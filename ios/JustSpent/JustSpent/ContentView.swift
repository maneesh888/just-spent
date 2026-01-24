import SwiftUI
import CoreData
import Intents
import IntentsUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // Manual fetch for robust stability (Bypassing NSFetchedResultsController crash in tests)
    @State private var expenses: [Expense] = []

    // Helper to fetch expenses manually using the environment's viewContext
    private func fetchExpenses() {
        let request: NSFetchRequest<Expense> = Expense.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "transactionDate", ascending: false)]
        do {
            expenses = try viewContext.fetch(request)
            #if DEBUG
            if TestDataManager.isUITesting() {
                print("🧪 [ContentView] Manually fetched \(expenses.count) expenses")
            }
            #endif
        } catch {
            print("❌ [ContentView] Error fetching expenses: \(error.localizedDescription)")
        }
    }

    @StateObject private var viewModel = ExpenseListViewModel()
    @StateObject private var speechRecognitionManager = SpeechRecognitionManager()
    @StateObject private var permissionManager = PermissionManager()
    @StateObject private var voiceTransactionManager = VoiceTransactionManager()

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
        let currencies = currencyCodes.compactMap { Currency.from(isoCode: $0) }
            .sorted { $0.displayName < $1.displayName }

        #if DEBUG
        if TestDataManager.isUITesting() {
            NSLog("🧪 [ContentView.activeCurrencies] Fetched %d total expenses", expenses.count)
            NSLog("🧪 [ContentView.activeCurrencies] Unique currency codes: %@", currencyCodes.sorted().joined(separator: ", "))
            NSLog("🧪 [ContentView.activeCurrencies] Currency.all has %d currencies", Currency.all.count)
            NSLog("🧪 [ContentView.activeCurrencies] Resolved %d Currency objects", currencies.count)
            if currencies.isEmpty && !currencyCodes.isEmpty {
                NSLog("❌ [ContentView.activeCurrencies] CRITICAL: Currency codes exist but Currency.from() returned nil!")
                NSLog("❌ This means Currency.all is likely empty!")
            }
        }
        #endif

        return currencies
    }

    /// Determine if we should show tabs (multiple currencies) or single list
    private var shouldShowTabs: Bool {
        let result = activeCurrencies.count > 1
        #if DEBUG
        if TestDataManager.isUITesting() {
            NSLog("🧪 [ContentView.shouldShowTabs] ========================================")
            NSLog("🧪 [ContentView.shouldShowTabs] DETERMINING VIEW STATE")
            NSLog("🧪 [ContentView.shouldShowTabs] Total expenses: %d", expenses.count)
            NSLog("🧪 [ContentView.shouldShowTabs] Active currencies count: %d", activeCurrencies.count)
            NSLog("🧪 [ContentView.shouldShowTabs] Active currencies: %@", activeCurrencies.map { $0.code }.joined(separator: ", "))
            NSLog("🧪 [ContentView.shouldShowTabs] Result: %@", result ? "MULTI-CURRENCY (tabs)" : "SINGLE/EMPTY")
            NSLog("🧪 [ContentView.shouldShowTabs] ========================================")
        }
        #endif
        return result
    }

    // MARK: - View Components

    /// Main content body - extracted to help Swift compiler
    @ViewBuilder
    private var mainContentBody: some View {
        if expenses.isEmpty {
            // Empty state (without floating button)
            let _ = {
                #if DEBUG
                if TestDataManager.isUITesting() {
                    print("🧪 [ContentView.mainContentBody] 📭 Showing EMPTY STATE")
                }
                #endif
            }()
            emptyStateView
                // Test marker for empty state
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("test_state_empty")
        } else if shouldShowTabs {
            // Multiple currencies → Tabbed interface
            let _ = {
                #if DEBUG
                if TestDataManager.isUITesting() {
                    NSLog("🧪 [ContentView.mainContentBody] 📊 Showing MULTI-CURRENCY TABBED VIEW")
                    NSLog("🧪 [ContentView.mainContentBody]    Currencies: %@", activeCurrencies.map { $0.code }.joined(separator: ", "))
                }
                #endif
            }()
            MultiCurrencyTabbedView(currencies: activeCurrencies)
                .environment(\.managedObjectContext, viewContext)
                // Test marker for multi-currency state
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("test_state_multi_currency")
        } else if let currency = activeCurrencies.first {
            // Single currency → Simple list view
            let _ = {
                #if DEBUG
                if TestDataManager.isUITesting() {
                    print("🧪 [ContentView.mainContentBody] 💰 Showing SINGLE CURRENCY VIEW: \(currency.code)")
                }
                #endif
            }()
            SingleCurrencyView(currency: currency)
                .environment(\.managedObjectContext, viewContext)
                // Test marker for single currency state
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("test_state_single_currency")
        } else {
            // Fallback to empty state (shouldn't happen, but safety)
            let _ = {
                #if DEBUG
                if TestDataManager.isUITesting() {
                    print("🧪 [ContentView.mainContentBody] ⚠️ FALLBACK TO EMPTY STATE (unexpected!)")
                }
                #endif
            }()
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
                    fetchExpenses() // Manual refresh for local state
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
        // Initial fetch
        fetchExpenses()
        
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
        Task {
            let result = await voiceTransactionManager.process(input: input, source: AppConstants.ExpenseSource.voiceSiri)
            await MainActor.run {
                siriMessage = result.message
                isErrorMessage = result.isError
                showingSiriSuccess = true
                if result.success {
                    Task {
                        await viewModel.loadExpenses()
                    }
                }
            }
        }
    }

    private func processVoiceTranscription(_ transcription: String) {
        #if DEBUG
        print(LocalizedStrings.debugProcessingTranscription(transcription))
        #endif

        Task {
            let result = await voiceTransactionManager.process(input: transcription, source: AppConstants.ExpenseSource.voiceRecognition)
            await MainActor.run {
                siriMessage = result.message
                isErrorMessage = result.isError
                showingSiriSuccess = true
                if result.success {
                    Task {
                        await viewModel.loadExpenses()
                    }
                }
            }
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
