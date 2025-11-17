// LogExpenseIntent.swift
import Intents

class LogExpenseIntent: INIntent {
    @NSManaged var category: ExpenseCategory
    @NSManaged var note: String?
    @NSManaged var merchant: String?
    @NSManaged var currency: String?
    @NSManaged var amount: Int64
}
