//
//  LocalizedStrings.swift
//  JustSpent
//
//  Centralized string localization helper
//  Now uses LocalizationManager (shared/localizations.json) as the single source of truth
//

import Foundation

/// Centralized access to all localized strings in the app
/// Usage: LocalizedStrings.appTitle
/// Note: This is now a wrapper around LocalizationManager which loads from shared/localizations.json
enum LocalizedStrings {

    private static let manager = LocalizationManager.shared

    // MARK: - App General
    static var appTitle: String { manager.appTitle }
    static var appSubtitle: String { manager.appSubtitle }
    static var totalLabel: String { manager.appTotalLabel }

    // MARK: - Empty State
    static var emptyStateNoExpenses: String { manager.emptyStateNoExpenses }
    static var emptyStateTapVoiceButton: String { manager.emptyStateTapVoiceButton }
    static var emptyStatePermissionsNeeded: String { manager.emptyStatePermissionsNeeded }
    static var emptyStateRecognitionUnavailable: String { manager.emptyStateRecognitionUnavailable }
    static var emptyStateGrantPermissions: String { manager.emptyStateGrantPermissions }

    // MARK: - Buttons
    static var buttonGrantPermissions: String { manager.buttonGrantPermissions }
    static var buttonOK: String { manager.buttonOK }
    static var buttonCancel: String { manager.buttonCancel }
    static var buttonRetry: String { manager.buttonRetry }
    static var buttonProcess: String { manager.buttonProcess }
    static var buttonGoToSettings: String { manager.buttonGoToSettings }

    // MARK: - Voice Recording
    static var voiceListening: String { manager.voiceListening }
    static var voiceProcessing: String { manager.voiceProcessing }
    static var voiceWillStopAuto: String { manager.voiceWillStopAuto }
    static var voiceEnterExpense: String { manager.voiceEnterExpense }
    static var voiceEnterNaturally: String { manager.voiceEnterNaturally }

    // MARK: - Permissions
    static var permissionTitleVoiceUnavailable: String { manager.get("permission.title.voiceUnavailable") }
    static var permissionMessageTempUnavailable: String { manager.get("permission.message.tempUnavailable") }
    static var permissionMessageUnavailable: String { manager.get("permission.message.unavailable") }

    // MARK: - Voice Recognition
    static var voiceRecognitionErrorTitle: String { manager.get("voiceRecognition.error.title") }
    static var voiceRecognitionSuccessTitle: String { manager.get("voiceRecognition.success.title") }
    static var voiceRecognitionEntryTitle: String { manager.get("voiceRecognition.entry.title") }
    static var voiceRecognitionSpeakClearly: String { manager.get("voiceRecognition.speakClearly") }

    // MARK: - Expense Processing (with format strings)
    static func expenseAddedSuccess(currency: String, amount: String, category: String, transcript: String) -> String {
        String(format: manager.get("expense.addedSuccess"), currency, amount, category, transcript)
    }

    static func expenseSmartProcessing(amount: String, category: String, transcript: String) -> String {
        String(format: manager.get("expense.smartProcessing"), amount, category, transcript)
    }

    static func expenseFailedToSave(_ error: String) -> String {
        String(format: manager.get("expense.failedToSave"), error)
    }

    static func expenseCouldNotUnderstand(_ input: String) -> String {
        String(format: manager.get("expense.couldNotUnderstand"), input)
    }

    static var expenseAddedViaVoice: String { manager.get("expense.addedViaVoice") }
    static var expenseAddedViaIntelligent: String { manager.get("expense.addedViaIntelligent") }

    // MARK: - Errors (with format strings)
    static func errorCouldNotExtract(_ command: String) -> String {
        String(format: manager.get("error.couldNotExtract"), command)
    }

    // MARK: - Debug Messages (for development)
    #if DEBUG
    static func debugReceivedURL(_ url: String) -> String {
        String(format: manager.get("debug.receivedURL"), url)
    }

    static func debugProcessingURL(_ text: String) -> String {
        String(format: manager.get("debug.processingURL"), text)
    }

    static func debugProcessing(_ command: String) -> String {
        String(format: manager.get("debug.processing"), command)
    }

    static func debugExtracted(amount: String, currency: String, category: String) -> String {
        String(format: manager.get("debug.extracted"), amount, currency, category)
    }

    static func debugSavedExpense(amount: String, category: String) -> String {
        String(format: manager.get("debug.savedExpense"), amount, category)
    }

    static func debugProcessingTranscription(_ text: String) -> String {
        String(format: manager.get("debug.processingTranscription"), text)
    }
    #endif

    // MARK: - Categories
    static var categoryFoodDining: String { manager.categoryFoodDining }
    static var categoryGrocery: String { manager.categoryGrocery }
    static var categoryTransportation: String { manager.categoryTransportation }
    static var categoryShopping: String { manager.categoryShopping }
    static var categoryEntertainment: String { manager.categoryEntertainment }
    static var categoryBills: String { manager.categoryBills }
    static var categoryHealthcare: String { manager.categoryHealthcare }
    static var categoryEducation: String { manager.categoryEducation }
    static var categoryOther: String { manager.categoryOther }
    static var categoryUnknown: String { manager.categoryUnknown }
}
