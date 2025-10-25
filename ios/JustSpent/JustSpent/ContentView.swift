import SwiftUI
import CoreData
import Intents
import IntentsUI
import NaturalLanguage
import Speech
import AVFoundation

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // Direct CoreData fetch for reliable initial load and auto-updates
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Expense.transactionDate, ascending: false)],
        animation: .default)
    private var expenses: FetchedResults<Expense>

    @StateObject private var viewModel = ExpenseListViewModel()
    @State private var showingSiriSuccess = false
    @State private var siriMessage = ""
    @State private var isErrorMessage = false // Track if current message is an error
    @State private var showingVoiceInput = false
    @State private var voiceInputText = ""

    // Speech Recognition States
    @State private var isRecording = false
    @State private var speechRecognizer: SFSpeechRecognizer?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()
    @State private var speechPermissionGranted = false
    @State private var microphonePermissionGranted = false
    @State private var speechRecognitionAvailable = false

    // Auto-stop detection states
    @State private var silenceTimer: Timer?
    @State private var lastSpeechTime = Date()
    @State private var hasDetectedSpeech = false
    @State private var silenceThreshold = AppConstants.VoiceRecording.silenceThreshold
    @State private var minimumSpeechDuration = AppConstants.VoiceRecording.minimumSpeechDuration

    // Permission UI states
    @State private var showingPermissionAlert = false
    @State private var permissionAlertTitle = ""
    @State private var permissionAlertMessage = ""
    @State private var permissionsChecked = false

    // Auto-recording integration
    @EnvironmentObject var lifecycleManager: AppLifecycleManager
    @EnvironmentObject var autoRecordingCoordinator: AutoRecordingCoordinator

    // User preferences for currency
    @StateObject private var userPreferences = UserPreferences.shared

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

    var body: some View {
        ZStack {
            // MARK: - Main Content View Based on Currency Count
            Group {
                if expenses.isEmpty {
                    // Empty state (without floating button)
                    emptyStateViewContent
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
                    emptyStateViewContent
                }
            }

            // MARK: - Floating Voice Button (Always Visible)
            FloatingVoiceButton(
                isRecording: $isRecording,
                hasDetectedSpeech: $hasDetectedSpeech,
                speechRecognitionAvailable: $speechRecognitionAvailable,
                speechPermissionGranted: $speechPermissionGranted,
                microphonePermissionGranted: $microphonePermissionGranted,
                onStartRecording: startRecording,
                onStopRecording: stopRecording,
                onPermissionAlert: {
                    showPermissionAlert(
                        title: LocalizedStrings.permissionTitleVoiceUnavailable,
                        message: LocalizedStrings.permissionMessageUnavailable
                    )
                }
            )
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
            if permissionsChecked {
                checkCurrentPermissions()
            }

            // Auto-recording disabled for app launch/foreground
            // (kept for future widget support)
            // DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            //     triggerAutoRecordingIfNeeded()
            // }
        }
        .onAppear {
            // Delay setup to ensure Info.plist is loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                setupSpeechRecognition()
                if !permissionsChecked {
                    requestInitialPermissions()
                } else {
                    // Refresh permission status in case user changed them in Settings
                    checkCurrentPermissions()
                }

                // Auto-recording disabled for app launch
                // (kept for future widget support)
                // #if DEBUG
                // print("📱 onAppear: Checking auto-recording conditions")
                // print("   - First Launch: \(lifecycleManager.isFirstLaunch)")
                // print("   - App State: \(lifecycleManager.appState)")
                // print("   - Speech Permission: \(speechPermissionGranted)")
                // print("   - Mic Permission: \(microphonePermissionGranted)")
                // print("   - Recognition Available: \(speechRecognitionAvailable)")
                // #endif
                // triggerAutoRecordingIfNeeded()
            }
        }
        .onChange(of: autoRecordingCoordinator.shouldStartRecording) { oldValue, newValue in
            // Observe auto-recording coordinator trigger
            if newValue && !isRecording {
                #if DEBUG
                print("🎙️ Auto-recording triggered by coordinator")
                #endif
                startRecording()
            }
        }
        .onChange(of: lifecycleManager.appState) { oldState, newState in
            // Cancel recording when app goes to background
            if newState == .background && isRecording {
                #if DEBUG
                print("🛑 App went to background while recording - cancelling recording without saving")
                #endif
                cleanupRecording()
                // Reset UI state
                siriMessage = ""
                showingSiriSuccess = false
                isErrorMessage = false
            }
        }
        .alert(permissionAlertTitle, isPresented: $showingPermissionAlert) {
            Button(LocalizedStrings.buttonGoToSettings) {
                openAppSettings()
            }
            Button(LocalizedStrings.buttonCancel, role: .cancel) { }
        } message: {
            Text(permissionAlertMessage)
        }
    }

    // MARK: - Empty State View Content

    private var emptyStateViewContent: some View {
        NavigationView {
            VStack {
                // Header with title and total
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStrings.appTitle)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text(LocalizedStrings.appSubtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(LocalizedStrings.totalLabel)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(CurrencyFormatter.shared.format(
                            amount: 0,
                            currency: userPreferences.defaultCurrency,
                            showSymbol: true,
                            showCode: false
                        ))
                        .font(.title2)
                        .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(Color(.systemBackground))

                // Empty state content
                VStack(spacing: 20) {
                    Spacer()

                    // Permission-aware icon and messaging
                    if speechRecognitionAvailable && speechPermissionGranted && microphonePermissionGranted {
                        Image(systemName: "mic.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        VStack(spacing: 12) {
                            Text(LocalizedStrings.emptyStateNoExpenses)
                                .font(.title2)
                                .foregroundColor(.secondary)

                            Text(LocalizedStrings.emptyStateTapVoiceButton)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    } else {
                        Image(systemName: speechRecognitionAvailable ? "mic.slash.circle" : "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)

                        VStack(spacing: 12) {
                            Text(LocalizedStrings.emptyStatePermissionsNeeded)
                                .font(.title2)
                                .foregroundColor(.secondary)

                            if !speechRecognitionAvailable {
                                Text(LocalizedStrings.emptyStateRecognitionUnavailable)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            } else {
                                Text(LocalizedStrings.emptyStateGrantPermissions)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)

                                Button(LocalizedStrings.buttonGrantPermissions) {
                                    openAppSettings()
                                }
                                .buttonStyle(.borderedProminent)
                                .padding(.top, 8)
                            }
                        }
                    }

                    Spacer()

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            }
        }
    }
    
    private func deleteExpenses(offsets: IndexSet) {
        for index in offsets {
            let expense = expenses[index]
            Task {
                await viewModel.deleteExpense(expense)
            }
        }
    }
    
    private func enableSiriSupport() {
        if #available(iOS 12.0, *) {
            // Create a user activity for the shortcut
            let activity = NSUserActivity(activityType: AppConstants.UserActivityType.logExpense)
            activity.title = LocalizedStrings.siriTitleLogExpense
            activity.userInfo = [
                "action": "logExpense",
                "source": "siri"
            ]
            activity.isEligibleForSearch = true
            activity.isEligibleForPrediction = true
            
            // Create shortcut from activity
            let shortcut = INShortcut(userActivity: activity)
            
            // Present the Add to Siri interface
            presentAddToSiri(shortcut: shortcut)
        } else {
            siriMessage = LocalizedStrings.siriRequiresiOS12
            showingSiriSuccess = true
        }
    }
    
    @available(iOS 12.0, *)
    private func presentAddToSiri(shortcut: INShortcut) {
        // Find the root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            print("❌ Could not find window")
            return
        }
        
        let addVoiceShortcutVC = INUIAddVoiceShortcutViewController(shortcut: shortcut)
        addVoiceShortcutVC.delegate = AddToSiriDelegate.shared
        
        // Present from the root view controller
        if let rootVC = window.rootViewController {
            rootVC.present(addVoiceShortcutVC, animated: true)
        }
    }
    
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
                        currency: extractedData.currency ?? AppConstants.Currency.defaultCurrency,
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

    // MARK: - Voice Command Processing
    // The extractExpenseData function has been removed and replaced with VoiceCommandParser.
    // Use VoiceCommandParser.shared.parseExpenseCommand() instead.
    // See: ios/JustSpent/JustSpent/Common/Utilities/VoiceCommandParser.swift

    // MARK: - Speech Recognition Functions

    private func setupSpeechRecognition() {
        // Don't do anything if we don't have proper Info.plist setup
        guard Bundle.main.object(forInfoDictionaryKey: "NSSpeechRecognitionUsageDescription") != nil else {
            print("❌ NSSpeechRecognitionUsageDescription not found in Info.plist")
            speechRecognitionAvailable = false
            return
        }
        
        // Initialize speech recognizer first
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        
        // Check if speech recognition is available
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("❌ Speech recognition not available on this device")
            speechRecognitionAvailable = false
            return
        }
        
        speechRecognitionAvailable = true
        checkCurrentPermissions()
    }
    
    private func checkCurrentPermissions() {
        // Check current speech recognition authorization status
        let speechAuthStatus = SFSpeechRecognizer.authorizationStatus()
        switch speechAuthStatus {
        case .authorized:
            speechPermissionGranted = true
            print("✅ Speech recognition already authorized")
        case .notDetermined:
            print("⏳ Speech recognition permission not determined")
            speechPermissionGranted = false
        case .denied, .restricted:
            speechPermissionGranted = false
            print("❌ Speech recognition permission denied or restricted")
        @unknown default:
            speechPermissionGranted = false
            print("❌ Unknown speech recognition status")
        }
        
        // Check microphone permission
        let micPermission = AVAudioSession.sharedInstance().recordPermission
        switch micPermission {
        case .granted:
            microphonePermissionGranted = true
            print("✅ Microphone permission already granted")
        case .undetermined:
            print("⏳ Microphone permission not determined")
            microphonePermissionGranted = false
        case .denied:
            microphonePermissionGranted = false
            print("❌ Microphone permission denied")
        @unknown default:
            microphonePermissionGranted = false
            print("❌ Unknown microphone permission status")
        }
        
        print("🎤 Microphone permission: \(micPermission.rawValue)")
        print("🗣️ Speech recognition status: \(speechAuthStatus.rawValue)")
    }
    
    
    private func startRecording() {
        // Check if speech recognition is available
        guard speechRecognitionAvailable, let recognizer = speechRecognizer else {
            showPermissionAlert(
                title: "Voice Recognition Unavailable",
                message: "Speech recognition is not available on this device. Voice recording features require speech recognition support."
            )
            return
        }
        
        // Check if recognizer is available
        guard recognizer.isAvailable else {
            showPermissionAlert(
                title: LocalizedStrings.permissionTitleServiceUnavailable,
                message: LocalizedStrings.permissionMessageTempUnavailable
            )
            return
        }

        // Check permissions
        guard speechPermissionGranted && microphonePermissionGranted else {
            if !speechPermissionGranted && !microphonePermissionGranted {
                showPermissionAlert(
                    title: LocalizedStrings.permissionTitleRequired,
                    message: LocalizedStrings.permissionMessageBothRequired
                )
            } else if !speechPermissionGranted {
                showPermissionAlert(
                    title: LocalizedStrings.permissionTitleSpeechRequired,
                    message: LocalizedStrings.permissionMessageSpeechRequired
                )
            } else {
                showPermissionAlert(
                    title: LocalizedStrings.permissionTitleMicRequired,
                    message: LocalizedStrings.permissionMessageMicRequired
                )
            }
            return
        }
        
        performRecording()
    }
    
    private func performRecording() {
        // Cancel any previous task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ Audio session setup failed: \(error)")
            siriMessage = "Failed to setup audio session"
            isErrorMessage = true
            showingSiriSuccess = true
            return
        }
        
        let inputNode = audioEngine.inputNode
        
        // Create recognition request
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.shouldReportPartialResults = true
        
        // Create recognition task
        guard let recognizer = speechRecognizer else {
            siriMessage = "Speech recognition is not available"
            isErrorMessage = true
            showingSiriSuccess = true
            return
        }
        
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            var finalTranscription = ""
            
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                print("🎙️ Transcription: \(transcription)")
                
                // Update speech detection state
                DispatchQueue.main.async {
                    if !transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        self.lastSpeechTime = Date()
                        self.hasDetectedSpeech = true
                        
                        // Reset silence timer since we detected speech
                        self.resetSilenceTimer()
                    }
                }
                
                isFinal = result.isFinal
                if isFinal {
                    finalTranscription = transcription
                }
            }
            
            // Handle completion (either final result or error)
            if isFinal || error != nil {
                // Stop audio processing if still running
                if self.audioEngine.isRunning {
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                }
                self.recognitionTask?.cancel()
                self.recognitionTask = nil
                
                DispatchQueue.main.async {
                    // Cancel silence timer
                    self.silenceTimer?.invalidate()
                    self.silenceTimer = nil
                    
                    if let error = error {
                        print("❌ Speech recognition error: \(error)")
                        // Only show error if it's not a cancellation (which is normal)
                        if (error as NSError).code != 301 { // kLSRErrorDomain Code=301 is cancellation
                            self.siriMessage = "Speech recognition failed: \(error.localizedDescription)"
                            self.isErrorMessage = true
                            self.showingSiriSuccess = true
                        }
                    } else if isFinal && !finalTranscription.isEmpty {
                        // Process successful final transcription
                        self.processVoiceTranscription(finalTranscription)
                    } else {
                        self.siriMessage = "No speech detected. Please try again."
                        self.isErrorMessage = true
                        self.showingSiriSuccess = true
                    }
                    
                    // Clean up UI state
                    self.cleanupRecording()
                }
            }
        }
        
        // Configure microphone input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isRecording = true
            hasDetectedSpeech = false
            lastSpeechTime = Date()
            
            // Start silence detection timer
            startSilenceDetection()
            
            print("🎙️ Recording started with auto-stop detection...")
        } catch {
            print("❌ Audio engine failed to start: \(error)")
            siriMessage = "Failed to start recording: \(error.localizedDescription)"
            isErrorMessage = true
            showingSiriSuccess = true
        }
    }
    
    private func stopRecording() {
        // This method is for manual stop (user taps stop button)
        print("🎙️ Manual stop requested")
        silenceTimer?.invalidate()
        silenceTimer = nil

        // Stop the audio engine first, before finishing the recognition task
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        // Now gracefully finish the recognition task
        // This will trigger the completion handler which will call cleanupRecording()
        recognitionTask?.finish()
    }
    
    private func cleanupRecording() {
        // Clean up UI and audio session
        isRecording = false
        hasDetectedSpeech = false

        // Cancel silence timer
        silenceTimer?.invalidate()
        silenceTimer = nil

        // Notify auto-recording coordinator if this was an auto-recording session
        if lifecycleManager.isAutoRecording {
            autoRecordingCoordinator.autoRecordingDidComplete()
        }

        // Reset audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false)
        } catch {
            print("❌ Failed to deactivate audio session: \(error)")
        }

        print("🎙️ Recording stopped")
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
                        currency: extractedData.currency ?? AppConstants.Currency.defaultCurrency,
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
    
    // MARK: - Auto-Recording Integration

    /**
     * Trigger auto-recording check through coordinator
     * Coordinator will verify all conditions before attempting to trigger
     */
    private func triggerAutoRecordingIfNeeded() {
        autoRecordingCoordinator.triggerAutoRecordingIfNeeded(
            isRecordingActive: isRecording,
            speechPermissionGranted: speechPermissionGranted,
            microphonePermissionGranted: microphonePermissionGranted,
            speechRecognitionAvailable: speechRecognitionAvailable
        )
    }

    // MARK: - Permission Management Functions

    private func requestInitialPermissions() {
        permissionsChecked = true
        
        // First request speech recognition permission
        requestSpeechPermissionAtLaunch { speechGranted in
            DispatchQueue.main.async {
                self.speechPermissionGranted = speechGranted
                
                // Then request microphone permission
                self.requestMicrophonePermissionAtLaunch { micGranted in
                    DispatchQueue.main.async {
                        self.microphonePermissionGranted = micGranted
                        self.handleInitialPermissionResults(speechGranted: speechGranted, micGranted: micGranted)
                    }
                }
            }
        }
    }
    
    private func requestSpeechPermissionAtLaunch(completion: @escaping (Bool) -> Void) {
        let currentStatus = SFSpeechRecognizer.authorizationStatus()
        
        switch currentStatus {
        case .authorized:
            completion(true)
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { authStatus in
                completion(authStatus == .authorized)
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    private func requestMicrophonePermissionAtLaunch(completion: @escaping (Bool) -> Void) {
        let currentPermission = AVAudioSession.sharedInstance().recordPermission
        
        switch currentPermission {
        case .granted:
            completion(true)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                completion(granted)
            }
        case .denied:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    private func handleInitialPermissionResults(speechGranted: Bool, micGranted: Bool) {
        if speechGranted && micGranted {
            print("✅ All permissions granted at launch")
            // Mark first launch as complete if this was first time
            if lifecycleManager.isFirstLaunch {
                lifecycleManager.completeFirstLaunch()
                print("✅ First launch completed - auto-recording will be available next time")
            }
            // No need to show any alert, everything is ready
        } else {
            // Don't show alerts at launch - just log the status
            // Users will see the permission status in the UI and can tap Grant Permissions if needed
            print("ℹ️ Some permissions not granted at launch - UI will reflect this")
            if !speechGranted {
                print("   - Speech Recognition permission needed")
            }
            if !micGranted {
                print("   - Microphone permission needed")
            }
        }
    }
    
    private func showPermissionAlert(title: String, message: String) {
        permissionAlertTitle = title
        permissionAlertMessage = message
        showingPermissionAlert = true
    }
    
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - Retry Function

    private func retryVoiceRecording() {
        // Reset error state
        isErrorMessage = false
        siriMessage = ""
        showingSiriSuccess = false

        // Start a new voice recording session
        startRecording()
    }

    // MARK: - Auto-Stop Detection Functions

    private func startSilenceDetection() {
        // Start a timer that checks for silence every 0.5 seconds
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.checkForSilence()
        }
    }
    
    private func resetSilenceTimer() {
        // This is called when we detect new speech
        // No need to restart the timer, just update the lastSpeechTime (already done in caller)
    }
    
    private func checkForSilence() {
        let now = Date()
        let timeSinceLastSpeech = now.timeIntervalSince(lastSpeechTime)
        let timeSinceRecordingStarted = now.timeIntervalSince(lastSpeechTime)
        
        // Only auto-stop if:
        // 1. We've detected some speech (to avoid immediate stop)
        // 2. It's been silent for longer than our threshold
        // 3. We've been recording for at least the minimum duration
        if hasDetectedSpeech && 
           timeSinceLastSpeech >= silenceThreshold &&
           timeSinceRecordingStarted >= minimumSpeechDuration {
            
            print("🔇 Auto-stopping recording after \(String(format: "%.1f", timeSinceLastSpeech))s of silence")
            
            DispatchQueue.main.async {
                self.autoStopRecording()
            }
        }
    }
    
    private func autoStopRecording() {
        // This method handles automatic stopping due to silence
        print("🎙️ Auto-stop triggered by silence detection")
        silenceTimer?.invalidate()
        silenceTimer = nil
        recognitionTask?.finish() // Gracefully finish - this will trigger the completion handler which calls cleanupRecording()
        // Note: cleanupRecording() is called in the recognition task completion handler, not here
    }
    
}

struct ExpenseRowView: View {
    let expense: Expense
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(expense.category ?? LocalizedStrings.categoryUnknown)
                        .font(.headline)
                    Spacer()
                    Text(formatAmount(expense.amount) + " " + (expense.currency ?? ""))
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                if let merchant = expense.merchant {
                    Text(merchant)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(formatDate(expense.transactionDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if expense.source == AppConstants.ExpenseSource.voiceSiri {
                        Image(systemName: "mic.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatAmount(_ amount: NSDecimalNumber?) -> String {
        guard let amount = amount else { return "0.00" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount) ?? "0.00"
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
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

// MARK: - Add to Siri Delegate

@available(iOS 12.0, *)
class AddToSiriDelegate: NSObject, INUIAddVoiceShortcutViewControllerDelegate {
    static let shared = AddToSiriDelegate()
    
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        
        controller.dismiss(animated: true) {
            if let voiceShortcut = voiceShortcut {
                print("✅ Successfully added Siri shortcut: '\(voiceShortcut.invocationPhrase)'")
                
                // Show success message
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SiriExpenseReceived"),
                        object: nil,
                        userInfo: [
                            "message": "🎉 Siri shortcut created!\n\nNow say: 'Hey Siri, \(voiceShortcut.invocationPhrase)'\n\nThe app will open and you can speak your expense naturally like:\n'I just spent 20 dollars for tea'"
                        ]
                    )
                }
            } else if let error = error {
                print("❌ Error adding Siri shortcut: \(error.localizedDescription)")
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SiriExpenseReceived"),
                        object: nil,
                        userInfo: [
                            "message": "❌ Failed to create Siri shortcut: \(error.localizedDescription)"
                        ]
                    )
                }
            }
        }
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true) {
            print("ℹ️ User cancelled adding Siri shortcut")
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("SiriExpenseReceived"),
                    object: nil,
                    userInfo: [
                        "message": "ℹ️ You can create a Siri shortcut anytime by tapping 'Enable Siri Support' again."
                    ]
                )
            }
        }
    }
}

