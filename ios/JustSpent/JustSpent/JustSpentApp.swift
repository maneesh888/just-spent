import SwiftUI
import NaturalLanguage
import AppIntents

@main
struct JustSpentApp: App {
    let persistenceController = PersistenceController.shared

    // App lifecycle management
    @StateObject private var lifecycleManager = AppLifecycleManager()
    @StateObject private var autoRecordingCoordinator: AutoRecordingCoordinator

    // Scene phase for lifecycle detection
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Create lifecycle manager first
        let lifecycle = AppLifecycleManager()
        _lifecycleManager = StateObject(wrappedValue: lifecycle)

        // Create auto-recording coordinator with dependency
        _autoRecordingCoordinator = StateObject(wrappedValue: AutoRecordingCoordinator(lifecycleManager: lifecycle))

        // Initialize currency system from JSON
        Currency.initialize()
        print("✅ Currency system initialized with \(Currency.all.count) currencies")

        // Initialize default currency based on locale if not already set
        // This ensures app ALWAYS has a default currency (module independence)
        UserPreferences.shared.initializeDefaultCurrency()
        print("💱 Default currency initialized")

        // Setup test environment if running UI tests
        if TestDataManager.isUITesting() {
            print("🧪 UI Testing mode detected - setting up test environment")
            let context = persistenceController.container.viewContext
            TestDataManager.shared.setupTestEnvironment(context: context)
        }

        // Register App Shortcuts for Siri discovery
        JustSpentShortcuts.updateAppShortcutParameters()
        print("🎤 App Shortcuts registered for Siri")

        // Donate app name to Siri vocabulary to help recognition
        donateAppNameToSiri()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(lifecycleManager)
                .environmentObject(autoRecordingCoordinator)
                .onContinueUserActivity(AppConstants.UserActivityType.logExpense) { userActivity in
                    handleSiriExpense(userActivity)
                }
                .onContinueUserActivity(AppConstants.UserActivityType.viewExpenses) { userActivity in
                    print(LocalizedStrings.debugReceivedURL("view_expenses"))
                }
                .onContinueUserActivity(AppConstants.UserActivityType.processVoiceCommand) { userActivity in
                    handleVoiceCommandProcessing(userActivity)
                }
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    handleScenePhaseChange(oldPhase: oldPhase, newPhase: newPhase)
                }
        }
    }

    // MARK: - Scene Phase Handling

    private func handleScenePhaseChange(oldPhase: ScenePhase, newPhase: ScenePhase) {
        let newAppState = AppState(from: newPhase)

        #if DEBUG
        print("📱 Scene phase changed: \(oldPhase) → \(newPhase) (AppState: \(newAppState))")
        #endif

        // Update lifecycle manager
        lifecycleManager.updateAppState(newAppState)

        // Handle foreground transition
        if lifecycleManager.didBecomeActive {
            #if DEBUG
            print("🔄 App returned to foreground - checking auto-recording conditions")
            #endif
            // Note: Auto-recording trigger happens in ContentView via coordinator
            // ContentView observes lifecycleManager and coordinator states
        }

        // Also trigger on initial active state (first launch or app start)
        if newAppState == .active {
            #if DEBUG
            print("🔄 App is now active - ContentView will check auto-recording")
            #endif
        }
    }
    
    private func handleSiriExpense(_ userActivity: NSUserActivity) {
        guard let userInfo = userActivity.userInfo,
              let amount = userInfo["amount"] as? Double,
              let category = userInfo["category"] as? String else {
            print("❌ Invalid Siri expense data")
            return
        }
        
        print("🎙️ Siri expense: $\(amount) for \(category)")
        
        // Show voice input dialog for intelligent processing
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name(AppConstants.Notification.voiceExpenseRequested),
                object: nil,
                userInfo: [
                    "action": "showVoiceInput"
                ]
            )
        }
        
        // For now, just trigger the voice input dialog
        // The user can then speak their expense naturally
        print("✅ Siri shortcut activated, showing voice input dialog")
    }
    
    private func handleVoiceCommandProcessing(_ userActivity: NSUserActivity) {
        print("🎙️ Processing voice command with NLP")
        
        // For now, when Siri activates this, show a text input dialog
        // This is a simpler approach that actually works
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name(AppConstants.Notification.voiceExpenseRequested),
                object: nil,
                userInfo: [
                    "action": "showVoiceInput"
                ]
            )
        }
    }
    
    private func processVoiceCommand(_ command: String) {
        print(LocalizedStrings.debugProcessing(command))

        // Use VoiceCommandParser for NLP processing
        let extractedData = VoiceCommandParser.shared.parseExpenseCommand(command)
        
        if let amount = extractedData.amount,
           let category = extractedData.category {
            
            // Save the expense
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
                        voiceTranscript: command
                    )

                    _ = try await repository.addExpense(expenseData)

                    // Show success notification
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: NSNotification.Name(AppConstants.Notification.siriExpenseReceived),
                            object: nil,
                            userInfo: [
                                "message": LocalizedStrings.expenseSmartProcessing(
                                    amount: String(amount),
                                    category: category,
                                    transcript: command
                                )
                            ]
                        )
                    }

                    #if DEBUG
                    print(LocalizedStrings.debugSavedExpense(amount: String(amount), category: category))
                    #endif
                    
                } catch {
                    print("❌ Failed to save intelligent expense: \(error)")
                }
            }
        } else {
            #if DEBUG
            print(LocalizedStrings.errorCouldNotExtract(command))
            #endif
        }
    }

    // MARK: - Voice Command Processing
    // Note: extractExpenseData function has been removed and replaced with VoiceCommandParser.shared.parseExpenseCommand()
    // See: ios/JustSpent/JustSpent/Common/Utilities/VoiceCommandParser.swift
    
    private func handleIncomingURL(_ url: URL) {
        #if DEBUG
        print(LocalizedStrings.debugReceivedURL(url.absoluteString))
        #endif

        // Handle URL scheme: justspent://expense?text=I%20just%20spent%2020%20dollars%20for%20tea
        if url.scheme == AppConstants.URLScheme.scheme && url.host == AppConstants.URLScheme.host {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

            if let textParam = components?.queryItems?.first(where: { $0.name == "text" })?.value {
                let decodedText = textParam.removingPercentEncoding ?? textParam
                #if DEBUG
                print(LocalizedStrings.debugProcessingURL(decodedText))
                #endif
                processVoiceCommand(decodedText)
            }
        }
    }

    // MARK: - Siri Vocabulary Donation

    private func donateAppNameToSiri() {
        // App Intents framework handles donations automatically
        // Just log that shortcuts are available
        print("✅ 'I Just Spent' phrase available in Siri")
    }
}