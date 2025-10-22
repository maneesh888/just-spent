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
            VStack(spacing: 32) {
                Spacer()

                // Welcome Header
                VStack(spacing: 16) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    Text("Welcome to Just Spent!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Select Your Default Currency")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // Currency Selection List
                List {
                    ForEach(Currency.allCases) { currency in
                        CurrencyOnboardingRow(
                            currency: currency,
                            isSelected: currency == selectedCurrency
                        ) {
                            selectedCurrency = currency
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .frame(maxHeight: 400)
                .scrollContentBackground(.hidden)

                // Helper Text
                Text("This will be used for expenses when no\ncurrency is specified in voice commands.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

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
                .padding(.horizontal)
                .padding(.bottom, 32)
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

                // Currency Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(currency.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(currency.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray.opacity(0.3))
                        .font(.title2)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
