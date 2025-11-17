// ExpenseCategory.swift
enum ExpenseCategory: String, IntentParameterValue {
    case transportation = "transportation"
    // other cases...
}

// LogExpenseIntent.swift
class LogExpenseIntent: INIntent {
    @NSManaged var category: ExpenseCategory
    // other parameters...
}
