//
//  LocalizedStrings.swift
//  JustSpent
//
//  Centralized string localization helper
//

import Foundation

/// Centralized access to all localized strings in the app
/// Usage: LocalizedStrings.appTitle instead of NSLocalizedString("app.title", comment: "")
enum LocalizedStrings {

    // MARK: - App General
    static let appTitle = NSLocalizedString("app.title", comment: "App name")
    static let appSubtitle = NSLocalizedString("app.subtitle", comment: "App subtitle")
    static let totalLabel = NSLocalizedString("app.total.label", comment: "Total label")

    // MARK: - Empty State
    static let emptyStateNoExpenses = NSLocalizedString("emptyState.noExpenses", comment: "No expenses message")
    static let emptyStateTapVoiceButton = NSLocalizedString("emptyState.tapVoiceButton", comment: "Tap voice button message")
    static let emptyStatePermissionsNeeded = NSLocalizedString("emptyState.permissionsNeeded", comment: "Permissions needed message")
    static let emptyStateRecognitionUnavailable = NSLocalizedString("emptyState.recognitionUnavailable", comment: "Recognition unavailable message")
    static let emptyStateGrantPermissions = NSLocalizedString("emptyState.grantPermissions", comment: "Grant permissions message")

    // MARK: - Buttons
    static let buttonGrantPermissions = NSLocalizedString("button.grantPermissions", comment: "Grant permissions button")
    static let buttonOK = NSLocalizedString("button.ok", comment: "OK button")
    static let buttonCancel = NSLocalizedString("button.cancel", comment: "Cancel button")
    static let buttonRetry = NSLocalizedString("button.retry", comment: "Retry button")
    static let buttonProcess = NSLocalizedString("button.process", comment: "Process button")
    static let buttonGoToSettings = NSLocalizedString("button.goToSettings", comment: "Go to settings button")

    // MARK: - Voice Recording
    static let voiceListening = NSLocalizedString("voice.listening", comment: "Listening state")
    static let voiceProcessing = NSLocalizedString("voice.processing", comment: "Processing state")
    static let voiceWillStopAuto = NSLocalizedString("voice.willStopAuto", comment: "Auto-stop message")
    static let voiceEnterExpense = NSLocalizedString("voice.enterExpense", comment: "Enter expense prompt")
    static let voiceEnterNaturally = NSLocalizedString("voice.enterNaturally", comment: "Natural input hint")

    // MARK: - Permissions
    static let permissionTitleVoiceUnavailable = NSLocalizedString("permission.title.voiceUnavailable", comment: "Voice unavailable title")
    static let permissionTitleServiceUnavailable = NSLocalizedString("permission.title.serviceUnavailable", comment: "Service unavailable title")
    static let permissionTitleRequired = NSLocalizedString("permission.title.required", comment: "Required permissions title")
    static let permissionTitleSpeechRequired = NSLocalizedString("permission.title.speechRequired", comment: "Speech required title")
    static let permissionTitleMicRequired = NSLocalizedString("permission.title.micRequired", comment: "Mic required title")

    static let permissionMessageUnavailable = NSLocalizedString("permission.message.unavailable", comment: "Unavailable message")
    static let permissionMessageTempUnavailable = NSLocalizedString("permission.message.tempUnavailable", comment: "Temporarily unavailable message")
    static let permissionMessageBothRequired = NSLocalizedString("permission.message.bothRequired", comment: "Both permissions message")
    static let permissionMessageSpeechRequired = NSLocalizedString("permission.message.speechRequired", comment: "Speech permission message")
    static let permissionMessageMicRequired = NSLocalizedString("permission.message.micRequired", comment: "Mic permission message")

    // MARK: - Voice Recognition
    static let voiceRecognitionErrorTitle = NSLocalizedString("voiceRecognition.error.title", comment: "Error title")
    static let voiceRecognitionSuccessTitle = NSLocalizedString("voiceRecognition.success.title", comment: "Success title")
    static let voiceRecognitionEntryTitle = NSLocalizedString("voiceRecognition.entry.title", comment: "Entry title")

    static func voiceRecognitionFailed(_ error: String) -> String {
        String(format: NSLocalizedString("voiceRecognition.failed", comment: "Failed message"), error)
    }

    static let voiceRecognitionNoSpeech = NSLocalizedString("voiceRecognition.noSpeech", comment: "No speech message")
    static let voiceRecognitionSpeakClearly = NSLocalizedString("voiceRecognition.speakClearly", comment: "Speak clearly message")

    // MARK: - Expense Processing
    static func expenseAddedSuccess(currency: String, amount: String, category: String, transcript: String) -> String {
        String(format: NSLocalizedString("expense.addedSuccess", comment: "Success message"), currency, amount, category, transcript)
    }

    static func expenseSmartProcessing(amount: String, category: String, transcript: String) -> String {
        String(format: NSLocalizedString("expense.smartProcessing", comment: "Smart processing message"), amount, category, transcript)
    }

    static func expenseFailedToSave(_ error: String) -> String {
        String(format: NSLocalizedString("expense.failedToSave", comment: "Failed to save"), error)
    }

    static func expenseCouldNotUnderstand(_ input: String) -> String {
        String(format: NSLocalizedString("expense.couldNotUnderstand", comment: "Could not understand"), input)
    }

    static let expenseAddedViaVoice = NSLocalizedString("expense.addedViaVoice", comment: "Added via voice")
    static let expenseAddedViaIntelligent = NSLocalizedString("expense.addedViaIntelligent", comment: "Added via intelligent processing")

    // MARK: - Categories
    static let categoryFoodDining = NSLocalizedString("category.foodDining", comment: "Food & Dining")
    static let categoryGrocery = NSLocalizedString("category.grocery", comment: "Grocery")
    static let categoryTransportation = NSLocalizedString("category.transportation", comment: "Transportation")
    static let categoryShopping = NSLocalizedString("category.shopping", comment: "Shopping")
    static let categoryEntertainment = NSLocalizedString("category.entertainment", comment: "Entertainment")
    static let categoryBills = NSLocalizedString("category.bills", comment: "Bills & Utilities")
    static let categoryHealthcare = NSLocalizedString("category.healthcare", comment: "Healthcare")
    static let categoryEducation = NSLocalizedString("category.education", comment: "Education")
    static let categoryOther = NSLocalizedString("category.other", comment: "Other")
    static let categoryUnknown = NSLocalizedString("category.unknown", comment: "Unknown")

    // MARK: - Source Types
    static let sourceManual = NSLocalizedString("source.manual", comment: "Manual")
    static let sourceVoiceSiri = NSLocalizedString("source.voiceSiri", comment: "Voice Siri")
    static let sourceVoiceRecognition = NSLocalizedString("source.voiceRecognition", comment: "Voice Recognition")
    static let sourceImport = NSLocalizedString("source.import", comment: "Import")

    // MARK: - Siri Integration
    static let siriTitleLogExpense = NSLocalizedString("siri.title.logExpense", comment: "Log expense title")
    static let siriInvalidData = NSLocalizedString("siri.invalidData", comment: "Invalid data")

    static func siriExpenseReceived(amount: String, category: String) -> String {
        String(format: NSLocalizedString("siri.expenseReceived", comment: "Expense received"), amount, category)
    }

    static let siriProcessing = NSLocalizedString("siri.processing", comment: "Processing")
    static let siriShortcutActivated = NSLocalizedString("siri.shortcutActivated", comment: "Shortcut activated")
    static let siriRequiresiOS12 = NSLocalizedString("siri.requiresiOS12", comment: "Requires iOS 12")

    static func siriShortcutCreated(_ phrase: String) -> String {
        String(format: NSLocalizedString("siri.shortcutCreated", comment: "Shortcut created"), phrase)
    }

    static func siriShortcutFailed(_ error: String) -> String {
        String(format: NSLocalizedString("siri.shortcutFailed", comment: "Shortcut failed"), error)
    }

    static let siriShortcutCancelled = NSLocalizedString("siri.shortcutCancelled", comment: "Shortcut cancelled")

    // MARK: - Errors
    static let errorAudioSessionSetup = NSLocalizedString("error.audioSessionSetup", comment: "Audio session error")

    static func errorAudioEngineFailed(_ error: String) -> String {
        String(format: NSLocalizedString("error.audioEngineFailed", comment: "Audio engine failed"), error)
    }

    static func errorDeactivateAudioSession(_ error: String) -> String {
        String(format: NSLocalizedString("error.deactivateAudioSession", comment: "Deactivate error"), error)
    }

    static let errorInvalidExpenseData = NSLocalizedString("error.invalidExpenseData", comment: "Invalid expense data")

    static func errorCouldNotExtract(_ command: String) -> String {
        String(format: NSLocalizedString("error.couldNotExtract", comment: "Could not extract"), command)
    }

    static func errorFailedToSave(_ error: String) -> String {
        String(format: NSLocalizedString("error.failedToSave", comment: "Failed to save"), error)
    }

    static let errorWindowNotFound = NSLocalizedString("error.windowNotFound", comment: "Window not found")

    // MARK: - Debug Messages (for development)
    #if DEBUG
    static func debugReceivedURL(_ url: String) -> String {
        String(format: NSLocalizedString("debug.receivedURL", comment: "Received URL"), url)
    }

    static func debugProcessingURL(_ text: String) -> String {
        String(format: NSLocalizedString("debug.processingURL", comment: "Processing URL"), text)
    }

    static func debugProcessing(_ command: String) -> String {
        String(format: NSLocalizedString("debug.processing", comment: "Processing"), command)
    }

    static func debugExtracted(amount: String, currency: String, category: String) -> String {
        String(format: NSLocalizedString("debug.extracted", comment: "Extracted"), amount, currency, category)
    }

    static func debugSavedExpense(amount: String, category: String) -> String {
        String(format: NSLocalizedString("debug.savedExpense", comment: "Saved expense"), amount, category)
    }

    static let debugRecordingStarted = NSLocalizedString("debug.recordingStarted", comment: "Recording started")
    static let debugRecordingStopped = NSLocalizedString("debug.recordingStopped", comment: "Recording stopped")
    static let debugManualStop = NSLocalizedString("debug.manualStop", comment: "Manual stop")
    static let debugAutoStop = NSLocalizedString("debug.autoStop", comment: "Auto stop")

    static func debugAutoStopAfterSilence(_ duration: Double) -> String {
        String(format: NSLocalizedString("debug.autoStopAfterSilence", comment: "Auto stop after silence"), duration)
    }

    static func debugTranscription(_ text: String) -> String {
        String(format: NSLocalizedString("debug.transcription", comment: "Transcription"), text)
    }

    static func debugProcessingTranscription(_ text: String) -> String {
        String(format: NSLocalizedString("debug.processingTranscription", comment: "Processing transcription"), text)
    }
    #endif
}
