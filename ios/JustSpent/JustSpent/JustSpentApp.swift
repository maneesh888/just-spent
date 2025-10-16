import SwiftUI
import NaturalLanguage

@main
struct JustSpentApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onContinueUserActivity("com.justspent.logExpense") { userActivity in
                    handleSiriExpense(userActivity)
                }
                .onContinueUserActivity("com.justspent.viewExpenses") { userActivity in
                    print("📊 Siri requested to view expenses")
                }
                .onContinueUserActivity("com.justspent.processVoiceCommand") { userActivity in
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
                name: NSNotification.Name("VoiceExpenseRequested"),
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
                name: NSNotification.Name("VoiceExpenseRequested"),
                object: nil,
                userInfo: [
                    "action": "showVoiceInput"
                ]
            )
        }
    }
    
    private func processVoiceCommand(_ command: String) {
        print("🧠 Processing: '\(command)'")
        
        // Extract data using NLP and regex patterns
        let extractedData = extractExpenseData(from: command)
        
        if let amount = extractedData.amount,
           let category = extractedData.category {
            
            // Save the expense
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
                        voiceTranscript: command
                    )
                    
                    _ = try await repository.addExpense(expenseData)
                    
                    // Show success notification
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("SiriExpenseReceived"),
                            object: nil,
                            userInfo: [
                                "message": "Smart processing: $\(amount) for \(category) from '\(command)'"
                            ]
                        )
                    }
                    
                    print("✅ Intelligently processed and saved expense: $\(amount) for \(category)")
                    
                } catch {
                    print("❌ Failed to save intelligent expense: \(error)")
                }
            }
        } else {
            print("❌ Could not extract expense data from: '\(command)'")
        }
    }
    
    private func extractExpenseData(from command: String) -> (amount: Double?, currency: String?, category: String?, merchant: String?) {
        let lowercased = command.lowercased()
        
        // Extract amount using regex
        let amountPattern = #"(\d+(?:\.\d{1,2})?)\s*(?:dollars?|usd|\$|aed|dirhams?)"#
        let amountRegex = try? NSRegularExpression(pattern: amountPattern, options: [])
        let amountRange = NSRange(location: 0, length: command.count)
        
        var amount: Double?
        if let match = amountRegex?.firstMatch(in: lowercased, options: [], range: amountRange) {
            let amountStr = String(lowercased[Range(match.range(at: 1), in: lowercased)!])
            amount = Double(amountStr)
        }
        
        // Extract currency
        var currency: String = "USD"
        if lowercased.contains("dirhams") || lowercased.contains("aed") {
            currency = "AED"
        } else if lowercased.contains("dollars") || lowercased.contains("usd") {
            currency = "USD"
        }
        
        // Extract category using keyword matching
        let categoryMappings: [String: String] = [
            // Food & Dining
            "food": "Food & Dining",
            "tea": "Food & Dining", 
            "coffee": "Food & Dining",
            "lunch": "Food & Dining",
            "dinner": "Food & Dining",
            "breakfast": "Food & Dining",
            "restaurant": "Food & Dining",
            "meal": "Food & Dining",
            "drink": "Food & Dining",
            
            // Grocery
            "grocery": "Grocery",
            "groceries": "Grocery",
            "supermarket": "Grocery",
            "market": "Grocery",
            
            // Transportation  
            "gas": "Transportation",
            "fuel": "Transportation",
            "taxi": "Transportation",
            "uber": "Transportation",
            "transport": "Transportation",
            "parking": "Transportation",
            
            // Shopping
            "shopping": "Shopping",
            "clothes": "Shopping",
            "store": "Shopping",
            
            // Entertainment
            "movie": "Entertainment",
            "cinema": "Entertainment",
            "concert": "Entertainment",
            
            // Bills
            "bill": "Bills & Utilities",
            "rent": "Bills & Utilities",
            "utility": "Bills & Utilities"
        ]
        
        var category: String = "Other" // Default category
        for (keyword, categoryName) in categoryMappings {
            if lowercased.contains(keyword) {
                category = categoryName
                break
            }
        }
        
        // Extract merchant (words after "at" or "from")
        var merchant: String?
        let merchantPattern = #"(?:at|from)\s+([a-zA-Z\s]+?)(?:\s|$)"#
        let merchantRegex = try? NSRegularExpression(pattern: merchantPattern, options: [])
        if let match = merchantRegex?.firstMatch(in: lowercased, options: [], range: amountRange) {
            merchant = String(command[Range(match.range(at: 1), in: command)!]).trimmingCharacters(in: .whitespaces)
        }
        
        return (amount: amount, currency: currency, category: category, merchant: merchant)
    }
    
    private func handleIncomingURL(_ url: URL) {
        print("🔗 Received URL: \(url)")
        
        // Handle URL scheme: justspent://expense?text=I%20just%20spent%2020%20dollars%20for%20tea
        if url.scheme == "justspent" && url.host == "expense" {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            
            if let textParam = components?.queryItems?.first(where: { $0.name == "text" })?.value {
                let decodedText = textParam.removingPercentEncoding ?? textParam
                print("📝 Processing URL text: '\(decodedText)'")
                processVoiceCommand(decodedText)
            }
        }
    }
}