//
//  SettingsView.swift
//  JustSpent
//
//  Created by Claude Code on 2025-10-19.
//  Settings screen with currency selection and preferences
//

import SwiftUI

struct SettingsView: View {

    // MARK: - State

    @StateObject private var preferences = UserPreferences.shared
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                // Currency Section
                Section {
                    currencyPicker
                } header: {
                    Text("Currency Settings")
                } footer: {
                    Text("All expenses will be displayed in your selected currency.")
                }

                // User Information Section
                Section {
                    userInfoRows
                } header: {
                    Text("User Information")
                }

                // App Information Section
                Section {
                    appInfoRows
                } header: {
                    Text("About")
                }

                // Reset Section
                Section {
                    resetButton
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Components

    private var currencyPicker: some View {
        Picker("Default Currency", selection: $preferences.defaultCurrency) {
            ForEach(Currency.all.sorted(by: { $0.displayName < $1.displayName })) { currency in
                HStack {
                    Text(currency.symbol)
                        .font(.title3)
                    Text(currency.displayName)
                    Spacer()
                    Text(currency.code)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .tag(currency)
            }
        }
        .pickerStyle(.navigationLink)
    }

    private var userInfoRows: some View {
        Group {
            if let user = preferences.currentUser {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(user.name ?? "User")
                        .foregroundColor(.secondary)
                }

                if let email = user.email {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(email)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Text("Member Since")
                    Spacer()
                    Text(formatDate(user.createdAt))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var appInfoRows: some View {
        Group {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Build")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                    .foregroundColor(.secondary)
            }
        }
    }

    private var resetButton: some View {
        Button(role: .destructive) {
            resetPreferences()
        } label: {
            HStack {
                Spacer()
                Text("Reset to Defaults")
                Spacer()
            }
        }
    }

    // MARK: - Helper Methods

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func resetPreferences() {
        preferences.resetToDefaults()
    }
}

// MARK: - Currency Selection Detail View

struct CurrencySelectionView: View {

    @Binding var selectedCurrency: Currency

    var body: some View {
        List {
            ForEach(Currency.all.sorted(by: { $0.displayName < $1.displayName })) { currency in
                CurrencyRow(currency: currency, isSelected: currency == selectedCurrency)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedCurrency = currency
                    }
            }
        }
        .navigationTitle("Select Currency (160+)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Currency Row Component

struct CurrencyRow: View {

    let currency: Currency
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Currency Symbol
            Text(currency.symbol)
                .font(.title2)
                .frame(width: 40)

            // Currency Info
            VStack(alignment: .leading, spacing: 4) {
                Text(currency.displayName)
                    .font(.body)

                Text(currency.code)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Checkmark for selected
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
                    .font(.headline)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

struct CurrencyRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CurrencyRow(currency: .usd, isSelected: true)
            CurrencyRow(currency: .aed, isSelected: false)
            CurrencyRow(currency: .eur, isSelected: false)
        }
        .previewLayout(.sizeThatFits)
    }
}
#endif
