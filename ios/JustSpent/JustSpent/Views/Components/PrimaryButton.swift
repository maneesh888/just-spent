//
//  PrimaryButton.swift
//  JustSpent
//
//  Created by Claude Code on 2025-11-08.
//  Primary button component with consistent styling across the app
//

import SwiftUI

/**
 Primary button component with consistent styling across the app

 Design specifications:
 - Height: 56pt (optimal touch target)
 - Corner radius: 12pt
 - Background: Blue color
 - Text: White, headline font
 - Full width layout

 Matches Android PrimaryButton for cross-platform consistency
 */
struct PrimaryButton: View {

    let text: String
    let action: () -> Void
    var enabled: Bool = true
    var accessibilityIdentifier: String = "primary_button"

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(enabled ? Color.blue : Color.blue.opacity(0.4))
                .cornerRadius(12)
        }
        .disabled(!enabled)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

// MARK: - Preview

#if DEBUG
struct PrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Enabled button
            PrimaryButton(text: "Continue", action: {})
                .padding()

            // Disabled button
            PrimaryButton(text: "Disabled", action: {}, enabled: false)
                .padding()
        }
    }
}
#endif
