import SwiftUI
import NaturalLanguage

@main
struct JustSpentApp: App {
    // Use State for persistence controller to allow async loading without blocking init
    // Renamed to avoid any potential conflict or caching issue
    @State private var appPersistence: PersistenceController? = nil

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

        // Reuse existing UserPreferences singleton logic which is safe (uses semaphore in init)
        
        // Initialize currency system from JSON
        Currency.initialize()
        NSLog("✅ Currency system initialized with %d currencies", Currency.all.count)

        // Initialize default currency based on locale if not already set
        UserPreferences.shared.initializeDefaultCurrency()
        NSLog("💱 Default currency initialized")
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if let controller = appPersistence {
                    ContentView()
                        .environment(\.managedObjectContext, controller.container.viewContext)
                        .environmentObject(lifecycleManager)
                        .environmentObject(autoRecordingCoordinator)
                } else {
                    // Use static text instead of ProgressView to avoid infinite animation blocking UI tests
                    Text("Loading...")
                        .onAppear {
                            NSLog("🔍 Loading view appeared, triggering loadPersistence")
                            loadPersistence()
                        }
                }
            }
            .onContinueUserActivity(AppConstants.UserActivityType.logExpense) { userActivity in
                handleSiriExpense(userActivity)
            }
            .onContinueUserActivity(AppConstants.UserActivityType.viewExpenses) { userActivity in
                #if DEBUG
                print(LocalizedStrings.debugReceivedURL("view_expenses"))
                #endif
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
    
    private func loadPersistence() {
        if appPersistence != nil { return }
        
        if TestDataManager.isUITesting() {
            NSLog("🧪 UI Testing Mode: Loading store asynchronously...")
            PersistenceController.loadAsync(inMemory: true) { controller in
                NSLog("🧪 Store loaded - initializing test environment")
                TestDataManager.shared.setupTestEnvironment(context: controller.container.viewContext)
                NSLog("🧪 Test environment setup complete")
                self.appPersistence = controller
            }
        } else {
            // Production: use shared controller (blocking but safe here as we are already in body)
            self.appPersistence = PersistenceController.shared
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
        #if DEBUG
        print(LocalizedStrings.debugProcessing(command))
        #endif

        Task {
            // Use local manager for background processing
            let manager = VoiceTransactionManager()
            let result = await manager.process(input: command, source: AppConstants.ExpenseSource.voiceSiri)
            
            if result.success {
                // Show success notification which updates UI
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: NSNotification.Name(AppConstants.Notification.siriExpenseReceived),
                        object: nil,
                        userInfo: [
                            "message": result.message
                        ]
                    )
                }
                
                #if DEBUG
                print("✅ Successfully processed voice command via Manager")
                #endif
            } else {
                #if DEBUG
                print("❌ Failed to process voice command: \(result.message)")
                #endif
            }
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
}