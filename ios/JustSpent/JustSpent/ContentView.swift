import SwiftUI
import CoreData
import Intents
import IntentsUI
import NaturalLanguage
import Speech
import AVFoundation

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = ExpenseListViewModel()
    @State private var showingSiriSuccess = false
    @State private var siriMessage = ""
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
    @State private var silenceThreshold: TimeInterval = 2.0 // Stop after 2 seconds of silence
    @State private var minimumSpeechDuration: TimeInterval = 1.0 // Require at least 1 second of speech
    
    // Permission UI states
    @State private var showingPermissionAlert = false
    @State private var permissionAlertTitle = ""
    @State private var permissionAlertMessage = ""
    @State private var permissionsChecked = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Just Spent")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text("Voice-enabled expense tracker")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Total")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(viewModel.formattedTotalSpending)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                    
                    // Content
                    if viewModel.expenses.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()
                            
                            // Permission-aware icon and messaging
                            if speechRecognitionAvailable && speechPermissionGranted && microphonePermissionGranted {
                                Image(systemName: "mic.circle")
                                    .font(.system(size: 60))
                                    .foregroundColor(.blue)
                                
                                VStack(spacing: 12) {
                                    Text("No expenses yet")
                                        .font(.title2)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Tap the voice button below to get started")
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
                                    Text("Voice features need permissions")
                                        .font(.title2)
                                        .foregroundColor(.secondary)
                                    
                                    if !speechRecognitionAvailable {
                                        Text("Speech recognition is not available on this device")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                    } else {
                                        Text("Grant Speech Recognition and Microphone permissions to use voice expense logging")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                        
                                        Button("Grant Permissions") {
                                            openAppSettings()
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .padding(.top, 8)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                    } else {
                        List {
                            ForEach(viewModel.expenses, id: \.id) { expense in
                                ExpenseRowView(expense: expense)
                            }
                            .onDelete(perform: deleteExpenses)
                        }
                        .padding(.bottom, 100) // Add padding to ensure list doesn't overlap floating button
                    }
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 8) {
                            // Listening indicator (when recording)
                            if isRecording {
                                VStack(spacing: 4) {
                                    HStack {
                                        Circle()
                                            .fill(hasDetectedSpeech ? Color.green : Color.red)
                                            .frame(width: 8, height: 8)
                                            .scaleEffect(isRecording ? 1.0 : 0.5)
                                            .animation(.easeInOut(duration: 0.5).repeatForever(), value: isRecording)
                                        Text(hasDetectedSpeech ? "Processing..." : "Listening...")
                                            .foregroundColor(hasDetectedSpeech ? .green : .red)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    
                                    // Auto-stop indicator
                                    Text("Will stop automatically when you finish speaking")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .cornerRadius(20)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                            
                            // Main floating button
                            Button(action: {
                                if isRecording {
                                    stopRecording()
                                } else {
                                    // Extra safety check before any speech recognition
                                    guard speechRecognitionAvailable else {
                                        showPermissionAlert(
                                            title: "Voice Recognition Unavailable",
                                            message: "Speech recognition is not available on this device."
                                        )
                                        return
                                    }
                                    startRecording()
                                }
                            }) {
                                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(isRecording ? Color.red : Color.blue)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                    .scaleEffect(isRecording ? 1.1 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: isRecording)
                            }
                            .disabled(!speechRecognitionAvailable || (!speechPermissionGranted || !microphonePermissionGranted))
                            .opacity((speechRecognitionAvailable && speechPermissionGranted && microphonePermissionGranted) ? 1.0 : 0.6)
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 34) // Safe area bottom padding
                }
            }
            .navigationBarHidden(true)
            .alert("Siri Success", isPresented: $showingSiriSuccess) {
                Button("OK") { }
            } message: {
                Text(siriMessage)
            }
            .alert("Voice Expense Entry", isPresented: $showingVoiceInput) {
                TextField("Say your expense...", text: $voiceInputText)
                Button("Process") {
                    if !voiceInputText.isEmpty {
                        processVoiceInput(voiceInputText)
                        voiceInputText = ""
                    }
                }
                Button("Cancel", role: .cancel) {
                    voiceInputText = ""
                }
            } message: {
                Text("Enter your expense naturally, like: 'I just spent 20 dollars for tea'")
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SiriExpenseReceived"))) { notification in
                if let message = notification.userInfo?["message"] as? String {
                    siriMessage = message
                    showingSiriSuccess = true
                    // Refresh the list
                    Task {
                        await viewModel.loadExpenses()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("VoiceExpenseRequested"))) { notification in
                showingVoiceInput = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Refresh permissions when app returns from background (e.g., from Settings)
                if permissionsChecked {
                    checkCurrentPermissions()
                }
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
                }
            }
            .alert(permissionAlertTitle, isPresented: $showingPermissionAlert) {
                Button("Go to Settings") {
                    openAppSettings()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(permissionAlertMessage)
            }
        }
    }
    
    private func deleteExpenses(offsets: IndexSet) {
        for index in offsets {
            let expense = viewModel.expenses[index]
            Task {
                await viewModel.deleteExpense(expense)
            }
        }
    }
    
    private func enableSiriSupport() {
        if #available(iOS 12.0, *) {
            // Create a user activity for the shortcut
            let activity = NSUserActivity(activityType: "com.justspent.logExpense")
            activity.title = "Log Expense"
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
            siriMessage = "Siri shortcuts require iOS 12 or later"
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
        // Use the same NLP processing as in JustSpentApp
        let extractedData = extractExpenseData(from: input)
        
        if let amount = extractedData.amount,
           let category = extractedData.category {
            
            Task {
                do {
                    let repository = ExpenseRepository()
                    let expenseData = ExpenseData(
                        amount: NSDecimalNumber(value: amount),
                        currency: extractedData.currency ?? "USD",
                        category: category,
                        merchant: extractedData.merchant,
                        notes: "Added via intelligent voice processing",
                        transactionDate: Date(),
                        source: "voice_siri",
                        voiceTranscript: input
                    )
                    
                    _ = try await repository.addExpense(expenseData)
                    
                    await MainActor.run {
                        siriMessage = "Smart processing success!\n💰 Amount: $\(amount)\n📂 Category: \(category)\n📝 From: '\(input)'"
                        showingSiriSuccess = true
                        Task {
                            await viewModel.loadExpenses()
                        }
                    }
                    
                } catch {
                    await MainActor.run {
                        siriMessage = "Failed to save expense: \(error.localizedDescription)"
                        showingSiriSuccess = true
                    }
                }
            }
        } else {
            siriMessage = "Could not understand: '\(input)'\n\nTry: 'I just spent 20 dollars for tea'"
            showingSiriSuccess = true
        }
    }
    
    private func extractExpenseData(from command: String) -> (amount: Double?, currency: String?, category: String?, merchant: String?) {
        let lowercased = command.lowercased()
        
        // Extract amount using improved regex patterns
        var amount: Double?
        var currency: String = "USD"
        
        // Try multiple patterns for better detection
        let patterns = [
            (#"(\d+(?:\.\d{1,2})?)\s*(?:dirhams?|aed)"#, "AED"),
            (#"(\d+(?:\.\d{1,2})?)\s*(?:dollars?|usd|\$)"#, "USD"),
            (#"(\d+(?:\.\d{1,2})?)\s*(?:euros?|eur|€)"#, "EUR"),
            (#"(\d+(?:\.\d{1,2})?)"#, "USD") // Default fallback for just numbers
        ]
        
        let range = NSRange(location: 0, length: command.count)
        
        for (pattern, curr) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: lowercased, options: [], range: range) {
                let amountStr = String(lowercased[Range(match.range(at: 1), in: lowercased)!])
                if let parsedAmount = Double(amountStr) {
                    amount = parsedAmount
                    currency = curr
                    break // Use first successful match
                }
            }
        }
        
        // Category mapping
        let categoryMappings: [String: String] = [
            "food": "Food & Dining", "tea": "Food & Dining", "coffee": "Food & Dining",
            "lunch": "Food & Dining", "dinner": "Food & Dining", "breakfast": "Food & Dining",
            "restaurant": "Food & Dining", "meal": "Food & Dining", "drink": "Food & Dining",
            "grocery": "Grocery", "groceries": "Grocery", "supermarket": "Grocery",
            "gas": "Transportation", "fuel": "Transportation", "taxi": "Transportation",
            "uber": "Transportation", "transport": "Transportation", "parking": "Transportation",
            "shopping": "Shopping", "clothes": "Shopping", "store": "Shopping",
            "movie": "Entertainment", "cinema": "Entertainment", "concert": "Entertainment",
            "bill": "Bills & Utilities", "rent": "Bills & Utilities", "utility": "Bills & Utilities"
        ]
        
        var category: String = "Other"
        for (keyword, categoryName) in categoryMappings {
            if lowercased.contains(keyword) {
                category = categoryName
                break
            }
        }
        
        // Extract merchant
        var merchant: String?
        let merchantPattern = #"(?:at|from)\s+([a-zA-Z\s]+?)(?:\s|$)"#
        let merchantRegex = try? NSRegularExpression(pattern: merchantPattern, options: [])
        if let match = merchantRegex?.firstMatch(in: lowercased, options: [], range: range) {
            merchant = String(command[Range(match.range(at: 1), in: command)!]).trimmingCharacters(in: .whitespaces)
        }
        
        return (amount: amount, currency: currency, category: category, merchant: merchant)
    }
    
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
                title: "Service Temporarily Unavailable",
                message: "Speech recognition is temporarily unavailable. Please try again in a few moments."
            )
            return
        }
        
        // Check permissions
        guard speechPermissionGranted && microphonePermissionGranted else {
            if !speechPermissionGranted && !microphonePermissionGranted {
                showPermissionAlert(
                    title: "Permissions Required",
                    message: "Voice recording requires both Speech Recognition and Microphone permissions. Please grant these permissions in Settings > Privacy & Security."
                )
            } else if !speechPermissionGranted {
                showPermissionAlert(
                    title: "Speech Recognition Permission Required",
                    message: "Please grant Speech Recognition permission in Settings > Privacy & Security > Speech Recognition to use voice features."
                )
            } else {
                showPermissionAlert(
                    title: "Microphone Permission Required",
                    message: "Please grant Microphone permission in Settings > Privacy & Security > Microphone to use voice features."
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
                // Stop audio processing first
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
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
                            self.showingSiriSuccess = true
                        }
                    } else if isFinal && !finalTranscription.isEmpty {
                        // Process successful final transcription
                        self.processVoiceTranscription(finalTranscription)
                    } else {
                        self.siriMessage = "No speech detected. Please try again."
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
            showingSiriSuccess = true
        }
    }
    
    private func stopRecording() {
        // This method is for manual stop (user taps stop button)
        print("🎙️ Manual stop requested")
        silenceTimer?.invalidate()
        silenceTimer = nil
        recognitionTask?.finish() // Gracefully finish instead of cancel
        cleanupRecording()
    }
    
    private func cleanupRecording() {
        // Clean up UI and audio session
        isRecording = false
        hasDetectedSpeech = false
        
        // Cancel silence timer
        silenceTimer?.invalidate()
        silenceTimer = nil
        
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
        print("🧠 Processing transcription: '\(transcription)'")
        
        // Validate input
        guard !transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            siriMessage = "No speech detected. Please try speaking clearly."
            showingSiriSuccess = true
            return
        }
        
        // Use the existing NLP processing function
        let extractedData = extractExpenseData(from: transcription)
        
        // Debug output
        print("🔍 Extracted - Amount: \(extractedData.amount ?? 0), Currency: \(extractedData.currency ?? "none"), Category: \(extractedData.category ?? "none")")
        
        if let amount = extractedData.amount,
           let category = extractedData.category {
            
            Task {
                do {
                    let repository = ExpenseRepository()
                    let expenseData = ExpenseData(
                        amount: NSDecimalNumber(value: amount),
                        currency: extractedData.currency ?? "USD",
                        category: category,
                        merchant: extractedData.merchant,
                        notes: "Added via voice recognition",
                        transactionDate: Date(),
                        source: "voice_recognition",
                        voiceTranscript: transcription
                    )
                    
                    _ = try await repository.addExpense(expenseData)
                    
                    await MainActor.run {
                        siriMessage = "✅ Voice expense added successfully!\n💰 Amount: \(extractedData.currency ?? "")$\(amount)\n📂 Category: \(category)\n🎙️ From: '\(transcription)'"
                        showingSiriSuccess = true
                        Task {
                            await viewModel.loadExpenses()
                        }
                    }
                    
                } catch {
                    await MainActor.run {
                        siriMessage = "❌ Failed to save expense: \(error.localizedDescription)"
                        showingSiriSuccess = true
                    }
                }
            }
        } else {
            siriMessage = "❌ Could not understand: '\(transcription)'\n\nTry saying: 'I just spent 20 dollars for tea'"
            showingSiriSuccess = true
        }
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
        recognitionTask?.finish() // Gracefully finish instead of cancel
        cleanupRecording()
    }
    
}

struct ExpenseRowView: View {
    let expense: Expense
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(expense.category ?? "Unknown")
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
                    
                    if expense.source == "voice_siri" {
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
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
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

