import SwiftUI
import NaturalLanguage

@main
struct JustSpentApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
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
                        currency: extractedData.currency ?? AppConstants.Currency.defaultCurrency,
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
}