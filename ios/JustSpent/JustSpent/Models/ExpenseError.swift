import Foundation

enum ExpenseError: LocalizedError {
    case invalidAmount(String)
    case categoryNotFound(String)
    case voiceParsingFailed(String)
    case databaseError(String)
    case networkError(String)
    case validationError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount(let message):
            return "Invalid amount: \(message)"
        case .categoryNotFound(let category):
            return "Category not found: \(category)"
        case .voiceParsingFailed(let message):
            return "Voice parsing failed: \(message)"
        case .databaseError(let message):
            return "Database error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .validationError(let message):
            return "Validation error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidAmount:
            return "Please enter a valid positive amount"
        case .categoryNotFound:
            return "Please select a valid category"
        case .voiceParsingFailed:
            return "Please try speaking more clearly or enter manually"
        case .databaseError:
            return "Please try again or restart the app"
        case .networkError:
            return "Please check your internet connection"
        case .validationError:
            return "Please check the entered information"
        }
    }
}