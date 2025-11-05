import SwiftUI

struct EmptyStateView: View {
    let speechRecognitionAvailable: Bool
    let speechPermissionGranted: Bool
    let microphonePermissionGranted: Bool
    let errorMessage: String?
    let onOpenSettings: () -> Void

    @StateObject private var userPreferences = UserPreferences.shared

    var body: some View {
        NavigationView {
            VStack {
                // Header with title and total
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStrings.appTitle)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .accessibilityIdentifier("empty_state_app_title")
                        Text(LocalizedStrings.appSubtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("empty_state_app_subtitle")
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(LocalizedStrings.totalLabel)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("empty_state_total_label")
                        Text(CurrencyFormatter.shared.format(
                            amount: 0,
                            currency: userPreferences.defaultCurrency,
                            showSymbol: true,
                            showCode: false
                        ))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .accessibilityIdentifier("empty_state_total_amount")
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(Color(.systemBackground))

                // Empty state content
                VStack(spacing: 20) {
                    Spacer()

                    // Permission-aware icon and messaging
                    if speechRecognitionAvailable && speechPermissionGranted && microphonePermissionGranted {
                        Image(systemName: "mic.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .accessibilityIdentifier("empty_state_mic_icon")

                        VStack(spacing: 12) {
                            Text(LocalizedStrings.emptyStateNoExpenses)
                                .font(.title2)
                                .foregroundColor(.secondary)
                                .accessibilityIdentifier("empty_state_no_expenses_title")

                            Text(LocalizedStrings.emptyStateTapVoiceButton)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .accessibilityIdentifier("empty_state_tap_voice_button_message")
                        }
                    } else {
                        Image(systemName: speechRecognitionAvailable ? "mic.slash.circle" : "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                            .accessibilityIdentifier("empty_state_permission_warning_icon")

                        VStack(spacing: 12) {
                            Text(LocalizedStrings.emptyStatePermissionsNeeded)
                                .font(.title2)
                                .foregroundColor(.secondary)
                                .accessibilityIdentifier("empty_state_permissions_needed_title")

                            if !speechRecognitionAvailable {
                                Text(LocalizedStrings.emptyStateRecognitionUnavailable)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .accessibilityIdentifier("empty_state_recognition_unavailable_message")
                            } else {
                                Text(LocalizedStrings.emptyStateGrantPermissions)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .accessibilityIdentifier("empty_state_grant_permissions_message")

                                Button(LocalizedStrings.buttonGrantPermissions) {
                                    onOpenSettings()
                                }
                                .buttonStyle(.borderedProminent)
                                .padding(.top, 8)
                                .accessibilityIdentifier("empty_state_grant_permissions_button")
                            }
                        }
                    }

                    Spacer()

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                            .accessibilityIdentifier("empty_state_error_message")
                    }
                }
            }
        }
    }
}
