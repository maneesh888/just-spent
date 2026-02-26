import Foundation
import CoreData

/// Result of a voice processing operation
struct VoiceProcessingResult {
    let message: String
    let isError: Bool
    let success: Bool
}

/// Manages the processing of voice commands into expense transactions
@MainActor
class VoiceTransactionManager: ObservableObject {
    
    /// Process a voice string input and attempt to create an expense
    /// - Parameters:
    ///   - input: The raw voice transcript
    ///   - source: The source of the input (e.g., "Siri", "Voice Recognition")
    /// - Returns: A result object containing (message, isError, success)
    func process(input: String, source: String) async -> VoiceProcessingResult {
        // Validate input
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return VoiceProcessingResult(
                message: LocalizedStrings.voiceRecognitionSpeakClearly,
                isError: true,
                success: false
            )
        }

        // Use VoiceCommandParser for NLP processing
        let extractedData = VoiceCommandParser.shared.parseExpenseCommand(input)

        #if DEBUG
        print(LocalizedStrings.debugExtracted(
            amount: String(extractedData.amount ?? 0),
            currency: extractedData.currency ?? "none",
            category: extractedData.category ?? "none"
        ))
        #endif

        if let amount = extractedData.amount,
           let category = extractedData.category {
            
            do {
                let repository = ExpenseRepository()
                let expenseData = ExpenseData(
                    amount: NSDecimalNumber(value: amount),
                    currency: extractedData.currency ?? AppConstants.CurrencyDefaults.defaultCurrency,
                    category: category,
                    merchant: extractedData.merchant,
                    notes: source == AppConstants.ExpenseSource.voiceSiri ? LocalizedStrings.expenseAddedViaIntelligent : LocalizedStrings.expenseAddedViaVoice,
                    transactionDate: Date(),
                    source: source,
                    voiceTranscript: input
                )

                _ = try await repository.addExpense(expenseData)

                let successMessage: String
                if source == AppConstants.ExpenseSource.voiceSiri {
                    successMessage = LocalizedStrings.expenseSmartProcessing(
                        amount: String(amount),
                        category: category,
                        transcript: input
                    )
                } else {
                    successMessage = LocalizedStrings.expenseAddedSuccess(
                        currency: extractedData.currency ?? "",
                        amount: String(amount),
                        category: category,
                        transcript: input
                    )
                }
                
                return VoiceProcessingResult(
                    message: successMessage,
                    isError: false,
                    success: true
                )

            } catch {
                return VoiceProcessingResult(
                    message: LocalizedStrings.expenseFailedToSave(error.localizedDescription),
                    isError: true,
                    success: false
                )
            }
        } else {
            return VoiceProcessingResult(
                message: LocalizedStrings.expenseCouldNotUnderstand(input),
                isError: true,
                success: false
            )
        }
    }
}
