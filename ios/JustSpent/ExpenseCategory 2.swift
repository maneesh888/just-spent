// ExpenseCategory.swift
import Intents

enum ExpenseCategory: String, IntentParameterValue {
    case transportation = "transportation"
    case grocery = "grocery"
    case other = "other"
    case education = "education"
    case healthcare = "healthcare"
    case entertainment = "entertainment"
    case shopping = "shopping"
    case billsUtilities = "billsUtilities"
    case foodDining = "foodDining"
}
