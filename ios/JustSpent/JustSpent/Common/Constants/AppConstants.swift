//
//  AppConstants.swift
//  JustSpent
//
//  Application-wide constants and configurations
//

import Foundation

enum AppConstants {

    // MARK: - User Activity Types
    enum UserActivityType {
        static let logExpense = "com.justspent.logExpense"
        static let viewExpenses = "com.justspent.viewExpenses"
        static let processVoiceCommand = "com.justspent.processVoiceCommand"
    }

    // MARK: - Notification Names
    enum Notification {
        static let siriExpenseReceived = "SiriExpenseReceived"
        static let voiceExpenseRequested = "VoiceExpenseRequested"
    }

    // MARK: - URL Schemes
    enum URLScheme {
        static let scheme = "justspent"
        static let host = "expense"
    }

    // MARK: - Voice Recording Configuration
    enum VoiceRecording {
        static let silenceThreshold: TimeInterval = 2.0
        static let minimumSpeechDuration: TimeInterval = 1.0
        static let silenceCheckInterval: TimeInterval = 0.5
    }

    // MARK: - Categories
    enum Category {
        static let foodDining = "Food & Dining"
        static let grocery = "Grocery"
        static let transportation = "Transportation"
        static let shopping = "Shopping"
        static let entertainment = "Entertainment"
        static let billsUtilities = "Bills & Utilities"
        static let healthcare = "Healthcare"
        static let education = "Education"
        static let other = "Other"

        static let allCategories = [
            foodDining,
            grocery,
            transportation,
            shopping,
            entertainment,
            billsUtilities,
            healthcare,
            education,
            other
        ]
    }

    // MARK: - Category Keywords Mapping
    enum CategoryKeywords {
        static let mappings: [(keywords: [String], category: String)] = [
            // Food & Dining - comprehensive food-related keywords
            (keywords: ["food", "tea", "coffee", "lunch", "dinner", "breakfast", "restaurant",
                       "meal", "drink", "cafe", "dining", "eat", "ate", "snack", "brunch",
                       "takeout", "takeaway", "delivery", "pizza", "burger", "sandwich",
                       "sushi", "dessert", "ice cream", "bakery", "starbucks", "mcdonald"],
             category: Category.foodDining),

            // Grocery - food shopping related
            (keywords: ["grocery", "groceries", "supermarket", "market", "food shopping",
                       "vegetables", "fruits", "produce", "walmart", "carrefour", "lulu"],
             category: Category.grocery),

            // Transportation - comprehensive transport and fuel keywords
            (keywords: ["gas", "fuel", "taxi", "uber", "transport", "transportation", "parking",
                       "petrol", "toll", "careem", "lyft", "metro", "subway", "train", "bus",
                       "diesel", "station", "refuel", "fill up", "car", "vehicle", "ride",
                       "trip", "travel", "flight", "airline", "ticket"],
             category: Category.transportation),

            // Shopping - retail and purchases
            (keywords: ["shopping", "clothes", "clothing", "store", "mall", "purchase", "buy", "bought",
                       "shoes", "accessories", "fashion", "retail", "amazon", "online shopping",
                       "electronics", "gadget", "phone", "laptop"],
             category: Category.shopping),

            // Entertainment - leisure and fun activities
            (keywords: ["movie", "cinema", "concert", "entertainment", "fun", "games", "theatre",
                       "sports", "gym", "fitness", "netflix", "streaming", "spotify", "music",
                       "hobby", "recreation", "amusement", "park"],
             category: Category.entertainment),

            // Bills & Utilities - recurring expenses
            (keywords: ["bill", "bills", "rent", "utility", "utilities", "electricity", "water",
                       "internet", "phone", "subscription", "insurance", "mortgage", "loan",
                       "payment", "recurring", "monthly", "annual"],
             category: Category.billsUtilities),

            // Healthcare - medical expenses
            (keywords: ["healthcare", "health", "doctor", "hospital", "medicine", "medical",
                       "pharmacy", "clinic", "prescription", "dentist", "therapy", "checkup",
                       "emergency", "surgery", "treatment"],
             category: Category.healthcare),

            // Education - learning and development
            (keywords: ["education", "school", "course", "training", "books", "learning", "tuition",
                       "college", "university", "class", "workshop", "seminar", "certification",
                       "textbook", "supplies", "fees"],
             category: Category.education)
        ]
    }

    // MARK: - Currency
    enum Currency {
        static let defaultCurrency = "USD"

        static let supportedCurrencies = [
            "USD",
            "AED",
            "EUR",
            "GBP",
            "INR"
        ]
    }

    // MARK: - Expense Source
    enum ExpenseSource {
        static let manual = "manual"
        static let voiceSiri = "voice_siri"
        static let voiceRecognition = "voice_recognition"
        static let `import` = "import"
    }

    // MARK: - Speech Recognition
    enum SpeechRecognition {
        static let locale = "en-US"
        static let maxRecognitionTime: TimeInterval = 60.0 // 1 minute max
    }

    // MARK: - UI Configuration
    enum UI {
        static let floatingButtonSize: CGFloat = 60.0
        static let floatingButtonBottomPadding: CGFloat = 34.0
        static let listBottomPadding: CGFloat = 100.0
    }

    // MARK: - Formatting
    enum Formatting {
        static let decimalPlaces = 2
        static let dateFormat = "medium"
    }
}
