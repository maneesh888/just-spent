//
//  AppHeaderCard.swift
//  JustSpent
//
//  Created by Claude Code on 2025-10-23.
//  Reusable header card component with app title and dynamic total display
//

import SwiftUI

/// Shared header card component used across all app states
/// Displays app title/subtitle on left, formatted total on right
/// Matches Android Material 3 design with iOS styling
struct AppHeaderCard: View {
    let formattedTotal: String
    let showPermissionWarning: Bool

    init(formattedTotal: String, showPermissionWarning: Bool = false) {
        self.formattedTotal = formattedTotal
        self.showPermissionWarning = showPermissionWarning
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left side: Title and subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStrings.appTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Text(LocalizedStrings.appSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if showPermissionWarning {
                        Image(systemName: "mic.slash.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                }
            }

            Spacer()

            // Right side: Total card
            VStack(alignment: .trailing, spacing: 4) {
                Text(LocalizedStrings.totalLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(formattedTotal)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green.opacity(0.2))
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground).opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

// MARK: - Gradient Background Component

/// Subtle gradient background matching Android design
struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.blue.opacity(0.1),
                Color.purple.opacity(0.05)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Preview

#Preview("With Balance") {
    ZStack {
        GradientBackground()

        VStack {
            AppHeaderCard(
                formattedTotal: "AED 1,234.56",
                showPermissionWarning: false
            )
            Spacer()
        }
    }
}

#Preview("Empty State") {
    ZStack {
        GradientBackground()

        VStack {
            AppHeaderCard(
                formattedTotal: "$0.00",
                showPermissionWarning: false
            )
            Spacer()
        }
    }
}

#Preview("With Permission Warning") {
    ZStack {
        GradientBackground()

        VStack {
            AppHeaderCard(
                formattedTotal: "$0.00",
                showPermissionWarning: true
            )
            Spacer()
        }
    }
}
