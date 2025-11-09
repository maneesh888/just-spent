import SwiftUI
import CoreData
import Intents
import IntentsUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // Direct CoreData fetch for reliable initial load and auto-updates
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Expense.transactionDate, ascending: false)],
        animation: .default)
    private var expenses: FetchedResults<Expense>

    @StateObject private var viewModel = ExpenseListViewModel()
    @StateObject private var speechRecognitionManager = SpeechRecognitionManager()
    @StateObject private var permissionManager = PermissionManager()

    @State private var showingSiriSuccess = false
    @State private var siriMessage = ""
    @State private var isErrorMessage = false // Track if current message is an error
    @State private var showingVoiceInput = false
    @State private var voiceInputText = ""

    // Permission UI states
    @State private var showingPermissionAlert = false
    @State private var permissionAlertTitle = ""
    @State private var permissionAlertMessage = ""

    // Auto-recording integration
    @EnvironmentObject var lifecycleManager: AppLifecycleManager
    @EnvironmentObject var autoRecordingCoordinator: AutoRecordingCoordinator

    // User preferences for currency
    @StateObject private var userPreferences = UserPreferences.shared

    // Onboarding state
    @State private var hasCompletedOnboarding: Bool = {
        // Force show onboarding if --show-onboarding flag is present
        if ProcessInfo.processInfo.arguments.contains("--show-onboarding") {
            return false
        }
        // Skip onboarding when running UI tests (unless --show-onboarding overrides)
        if ProcessInfo.processInfo.arguments.contains("--uitesting") ||
           ProcessInfo.processInfo.arguments.contains("--skip-onboarding") {
            return true
        }
        return UserPreferences.shared.hasCompletedOnboarding()
    }()

    // MARK: - Currency Detection

    /// Get distinct currencies from expenses
    private var activeCurrencies: [Currency] {
        let currencyCodes = Set(expenses.compactMap { $0.currency })
        return currencyCodes.compactMap { Currency.from(isoCode: $0) }
            .sorted { $0.displayName < $1.displayName }
    }

    /// Determine if we should show tabs (multiple currencies) or single list
    private var shouldShowTabs: Bool {
        return activeCurrencies.count > 1
    }

    // MARK: - View Components

    /// Main content body - extracted to help Swift compiler
    @ViewBuilder
    private var mainContentBody: some View {
        if expenses.isEmpty {
            // Empty state (without floating button)
            emptyStateView
        } else if shouldShowTabs {
            // Multiple currencies → Tabbed interface
            MultiCurrencyTabbedView(currencies: activeCurrencies)
                .environment(\.managedObjectContext, viewContext)
        } else if let currency = activeCurrencies.first {
            // Single currency → Simple list view
            SingleCurrencyView(currency: currency)
                .environment(\.managedObjectContext, viewContext)
        } else {
            // Fallback to empty state (shouldn't happen, but safety)
            emptyStateView
        }
    }

    /// Empty state view - extracted to avoid duplication
    private var emptyStateView: some View {
        EmptyStateView(
            speechRecognitionAvailable: speechRecognitionManager.speechRecognitionAvailable,
            speechPermissionGranted: permissionManager.speechPermissionGranted,
            microphonePermissionGranted: permissionManager.microphonePermissionGranted,
            errorMessage: viewModel.errorMessage,
            onOpenSettings: permissionManager.openAppSettings
        )
    }

    /// Floating voice button - extracted to help Swift compiler
    private var floatingVoiceButton: some View {
        FloatingVoiceButton(
            isRecording: $speechRecognitionManager.isRecording,
            hasDetectedSpeech: $speechRecognitionManager.hasDetectedSpeech,
            speechRecognitionAvailable: $speechRecognitionManager.speechRecognitionAvailable,
            speechPermissionGranted: $permissionManager.speechPermissionGranted,
            microphonePermissionGranted: $permissionManager.microphonePermissionGranted,
            onStartRecording: speechRecognitionManager.startRecording,
            onStopRecording: speechRecognitionManager.stopRecording,
            onPermissionAlert: handlePermissionAlert
        )
    }

    /// Permission alert handler - extracted to reduce inline closure complexity
    private func handlePermissionAlert() {
        showPermissionAlert(
            title: LocalizedStrings.permissionTitleVoiceUnavailable,
            message: LocalizedStrings.permissionMessageUnavailable
        )
    }

    var body: some View {
        if !hasCompletedOnboarding {
            // Show onboarding screen on first launch
            CurrencyOnboardingView(isOnboardingComplete: $hasCompletedOnboarding)
        } else {
            // Show main app content
            mainAppContent
        }
    }

    // MARK: - Main App Content

    private var mainAppContent: some View {
        ZStack {
            // MARK: - Main Content View Based on Currency Count
            mainContentBody

            // MARK: - Floating Voice Button (Always Visible)
            floatingVoiceButton
        }
        .alert(isErrorMessage ? LocalizedStrings.voiceRecognitionErrorTitle : LocalizedStrings.voiceRecognitionSuccessTitle, isPresented: $showingSiriSuccess) {
            Button(LocalizedStrings.buttonOK) {
                isErrorMessage = false
            }
            if isErrorMessage {
                Button(LocalizedStrings.buttonRetry) {
                    retryVoiceRecording()
                }
            }
        } message: {
            Text(siriMessage)
        }
        .alert(LocalizedStrings.voiceRecognitionEntryTitle, isPresented: $showingVoiceInput) {
            TextField(LocalizedStrings.voiceEnterExpense, text: $voiceInputText)
            Button(LocalizedStrings.buttonProcess) {
                if !voiceInputText.isEmpty {
                    processVoiceInput(voiceInputText)
                    voiceInputText = ""
                }
            }
            Button(LocalizedStrings.buttonCancel, role: .cancel) {
                voiceInputText = ""
            }
        } message: {
            Text(LocalizedStrings.voiceEnterNaturally)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name(AppConstants.Notification.siriExpenseReceived))) { notification in
            if let message = notification.userInfo?["message"] as? String {
                siriMessage = message
                showingSiriSuccess = true
                // Refresh the list
                Task {
                    await viewModel.loadExpenses()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name(AppConstants.Notification.voiceExpenseRequested))) { notification in
            showingVoiceInput = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Refresh permissions when app returns from background (e.g., from Settings)
            if permissionManager.permissionsChecked {
                permissionManager.checkCurrentPermissions()
            }
        }
        .onAppear {
            setupViewOnAppear()
        }
        .onChange(of: autoRecordingCoordinator.shouldStartRecording) { oldValue, newValue in
            // Observe auto-recording coordinator trigger
            if newValue && !speechRecognitionManager.isRecording {
                #if DEBUG
                print("🎙️ Auto-recording triggered by coordinator")
                #endif
                speechRecognitionManager.startRecording()
            }
        }
        .onChange(of: lifecycleManager.appState) { oldState, newState in
            // Cancel recording when app goes to background
            if newState == .background && speechRecognitionManager.isRecording {
                #if DEBUG
                print("🛑 App went to background while recording - cancelling recording without saving")
                #endif
                speechRecognitionManager.cleanupRecording()
                // Reset UI state
                siriMessage = ""
                showingSiriSuccess = false
                isErrorMessage = false
            }
        }
        .alert(permissionAlertTitle, isPresented: $showingPermissionAlert) {
            Button(LocalizedStrings.buttonGoToSettings) {
                permissionManager.openAppSettings()
            }
            Button(LocalizedStrings.buttonCancel, role: .cancel) { }
        } message: {
            Text(permissionAlertMessage)
        }
    }

    // MARK: - Setup

    private func setupViewOnAppear() {
        // Setup speech recognition callbacks
        speechRecognitionManager.onTranscriptionResult = { transcription in
            processVoiceTranscription(transcription)
        }

        speechRecognitionManager.onError = { message, isError in
            siriMessage = message
            isErrorMessage = isError
            showingSiriSuccess = true
        }

        // Delay setup to ensure Info.plist is loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            speechRecognitionManager.setupSpeechRecognition()
            if !permissionManager.permissionsChecked {
                permissionManager.requestInitialPermissions(lifecycleManager: lifecycleManager) {
                    // Permissions request completed
                }
            } else {
                // Refresh permission status in case user changed them in Settings
                permissionManager.checkCurrentPermissions()
            }
        }
    }

    // MARK: - Voice Command Processing

    private func processVoiceInput(_ input: String) {
        // Use VoiceCommandParser for NLP processing
        let extractedData = VoiceCommandParser.shared.parseExpenseCommand(input)

        if let amount = extractedData.amount,
           let category = extractedData.category {

            Task {
                do {
                    let repository = ExpenseRepository()
                    let expenseData = ExpenseData(
                        amount: NSDecimalNumber(value: amount),
                        currency: extractedData.currency ?? AppConstants.CurrencyDefaults.defaultCurrency,
                        category: category,
                        merchant: extractedData.merchant,
                        notes: LocalizedStrings.expenseAddedViaIntelligent,
                        transactionDate: Date(),
                        source: AppConstants.ExpenseSource.voiceSiri,
                        voiceTranscript: input
                    )

                    _ = try await repository.addExpense(expenseData)

                    await MainActor.run {
                        siriMessage = LocalizedStrings.expenseSmartProcessing(
                            amount: String(amount),
                            category: category,
                            transcript: input
                        )
                        showingSiriSuccess = true
                        Task {
                            await viewModel.loadExpenses()
                        }
                    }

                } catch {
                    await MainActor.run {
                        siriMessage = LocalizedStrings.expenseFailedToSave(error.localizedDescription)
                        isErrorMessage = true
                        showingSiriSuccess = true
                    }
                }
            }
        } else {
            siriMessage = LocalizedStrings.expenseCouldNotUnderstand(input)
            isErrorMessage = true
            showingSiriSuccess = true
        }
    }

    private func processVoiceTranscription(_ transcription: String) {
        print(LocalizedStrings.debugProcessingTranscription(transcription))

        // Validate input
        guard !transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            siriMessage = LocalizedStrings.voiceRecognitionSpeakClearly
            isErrorMessage = true
            showingSiriSuccess = true
            return
        }

        // Use VoiceCommandParser for NLP processing
        let extractedData = VoiceCommandParser.shared.parseExpenseCommand(transcription)

        // Debug output
        #if DEBUG
        print(LocalizedStrings.debugExtracted(
            amount: String(extractedData.amount ?? 0),
            currency: extractedData.currency ?? "none",
            category: extractedData.category ?? "none"
        ))
        #endif

        if let amount = extractedData.amount,
           let category = extractedData.category {

            Task {
                do {
                    let repository = ExpenseRepository()
                    let expenseData = ExpenseData(
                        amount: NSDecimalNumber(value: amount),
                        currency: extractedData.currency ?? AppConstants.CurrencyDefaults.defaultCurrency,
                        category: category,
                        merchant: extractedData.merchant,
                        notes: LocalizedStrings.expenseAddedViaVoice,
                        transactionDate: Date(),
                        source: AppConstants.ExpenseSource.voiceRecognition,
                        voiceTranscript: transcription
                    )

                    _ = try await repository.addExpense(expenseData)

                    await MainActor.run {
                        siriMessage = LocalizedStrings.expenseAddedSuccess(
                            currency: extractedData.currency ?? "",
                            amount: String(amount),
                            category: category,
                            transcript: transcription
                        )
                        showingSiriSuccess = true
                        Task {
                            await viewModel.loadExpenses()
                        }
                    }

                } catch {
                    await MainActor.run {
                        siriMessage = LocalizedStrings.expenseFailedToSave(error.localizedDescription)
                        isErrorMessage = true
                        showingSiriSuccess = true
                    }
                }
            }
        } else {
            siriMessage = LocalizedStrings.expenseCouldNotUnderstand(transcription)
            isErrorMessage = true
            showingSiriSuccess = true
        }
    }

    // MARK: - Helper Methods

    private func showPermissionAlert(title: String, message: String) {
        permissionAlertTitle = title
        permissionAlertMessage = message
        showingPermissionAlert = true
    }

    private func retryVoiceRecording() {
        // Reset error state
        isErrorMessage = false
        siriMessage = ""
        showingSiriSuccess = false

        // Start a new voice recording session
        speechRecognitionManager.startRecording()
    }
}

#Preview {
    let lifecycle = AppLifecycleManager()
    let coordinator = AutoRecordingCoordinator(lifecycleManager: lifecycle)

    return ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(lifecycle)
        .environmentObject(coordinator)
}
