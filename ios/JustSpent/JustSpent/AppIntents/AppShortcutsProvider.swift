//
//  AppShortcutsProvider.swift
//  JustSpent
//
//  Provides app shortcuts for Siri discovery
//

import AppIntents

struct JustSpentShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // Log Expense Shortcuts
        AppShortcut(
            intent: LogExpenseIntent(),
            phrases: [
                "\(.applicationName)",
                "Log \(.applicationName)",
                "Track \(.applicationName)",
                "Add \(.applicationName)",
                "Record \(.applicationName)"
            ],
            shortTitle: "Log Expense",
            systemImageName: "dollarsign.circle"
        )

        // View Expenses Shortcuts
        AppShortcut(
            intent: ViewExpensesIntent(),
            phrases: [
                "Show my expenses in \(.applicationName)",
                "View my spending in \(.applicationName)",
                "Check my expenses in \(.applicationName)",
                "View expenses in \(.applicationName)",
                "Show spending in \(.applicationName)"
            ],
            shortTitle: "View Expenses",
            systemImageName: "list.bullet"
        )
    }

    static var shortcutTileColor: ShortcutTileColor {
        .blue
    }
}
