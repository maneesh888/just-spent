//
//  CurrencyOnboardingView.swift
//  JustSpent
//
//  Created by Claude Code on 2025-10-19.
//  First-launch onboarding for default currency selection
//

import SwiftUI

struct CurrencyOnboardingView: View {

    @StateObject private var userPreferences = UserPreferences.shared
    @State private var selectedCurrency: Currency = Currency.default
    @Binding var isOnboardingComplete: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // App Title (for test discoverability)
                    Text(LocalizedStrings.appTitle)
                        .font(.caption2)
                        .foregroundColor(.clear)
                        .frame(height: 0)
                        .accessibilityHidden(true)

                    // Welcome Header
                    VStack(spacing: 12) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.blue)
                            .accessibilityIdentifier("onboarding_icon")

                        Text("Welcome to Just Spent!")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("onboarding_title")

                        Text("We've pre-selected your currency based on your location")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("onboarding_subtitle")
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // Currency Selection List (All 160+ currencies available)
                    List {
                        ForEach(Currency.all.sorted(by: { $0.displayName < $1.displayName })) { currency in
                            CurrencyOnboardingRow(
                                currency: currency,
                                isSelected: currency == selectedCurrency
                            ) {
                                selectedCurrency = currency
                            }
                            .accessibilityIdentifier("currency_option_\(currency.code)")
                        }
                    }
                    .listStyle(.insetGrouped)
                    .frame(maxHeight: 400)
                    .scrollContentBackground(.hidden)
                    .accessibilityIdentifier("currency_list")

                    // Helper Text
                    Text("Choose from 160+ world currencies.\nScroll to find your preferred currency.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .accessibilityIdentifier("onboarding_helper_text")

                    Spacer()

                    // Continue Button
                    Button(action: completeOnboarding) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .accessibilityIdentifier("onboarding_continue_button")
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func completeOnboarding() {
        // Save selected currency
        userPreferences.setDefaultCurrency(selectedCurrency)

        // Mark onboarding as complete
        userPreferences.completeOnboarding()

        // Dismiss onboarding
        withAnimation {
            isOnboardingComplete = true
        }
    }
}

// MARK: - Currency Onboarding Row

struct CurrencyOnboardingRow: View {

    let currency: Currency
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Currency Symbol
                Text(currency.symbol)
                    .font(.system(size: 32))
                    .frame(width: 50)
                    .accessibilityIdentifier("currency_symbol_\(currency.code)")

                // Currency Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(currency.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .accessibilityIdentifier("currency_name_\(currency.code)")

                    Text(currency.code)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityIdentifier("currency_code_\(currency.code)")
                }

                Spacer()

                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                        .accessibilityIdentifier("currency_selected_\(currency.code)")
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray.opacity(0.3))
                        .font(.title2)
                        .accessibilityIdentifier("currency_unselected_\(currency.code)")
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(currency.displayName) (\(currency.code))")
        .accessibilityIdentifier(currency.code)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#if DEBUG
struct CurrencyOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        CurrencyOnboardingView(isOnboardingComplete: .constant(false))
    }
}

struct CurrencyOnboardingRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            CurrencyOnboardingRow(currency: .usd, isSelected: true) {}
            CurrencyOnboardingRow(currency: .aed, isSelected: false) {}
            CurrencyOnboardingRow(currency: .eur, isSelected: false) {}
        }
        .listStyle(.insetGrouped)
    }
}
#endif
