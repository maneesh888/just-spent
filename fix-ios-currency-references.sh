#!/bin/bash
# Script to fix all Currency enum to struct references in iOS codebase

set -e

echo "🔧 Fixing Currency enum to struct references in iOS codebase..."

# Navigate to iOS directory
cd "$(dirname "$0")/ios/JustSpent/JustSpent"

# Fix UserPreferences.swift
echo "📝 Fixing UserPreferences.swift..."
sed -i.bak 's/Currency(rawValue:/Currency.from(isoCode:/g' Services/UserPreferences.swift
sed -i.bak 's/currency\.rawValue/currency.code/g' Services/UserPreferences.swift
sed -i.bak 's/Currency\.default\.rawValue/Currency.default.code/g' Services/UserPreferences.swift
sed -i.bak 's/localeCurrency\.rawValue/localeCurrency.code/g' Services/UserPreferences.swift
sed -i.bak 's/defaultCurrency\.rawValue/defaultCurrency.code/g' Services/UserPreferences.swift
sed -i.bak 's/newValue\.rawValue/newValue.code/g' Services/UserPreferences.swift

# Fix VoiceCurrencyDetector.swift
echo "📝 Fixing VoiceCurrencyDetector.swift..."
sed -i.bak 's/Currency\.allCases/Currency.all/g' Services/VoiceCurrencyDetector.swift
sed -i.bak 's/currency\.rawValue/currency.code/g' Services/VoiceCurrencyDetector.swift

# Fix CurrencyFormatter.swift
echo "📝 Fixing CurrencyFormatter.swift..."
sed -i.bak 's/currency\.rawValue/currency.code/g' Services/CurrencyFormatter.swift
sed -i.bak 's/Currency\.allCases/Currency.common/g' Services/CurrencyFormatter.swift
sed -i.bak 's/curr\.rawValue/curr.code/g' Services/CurrencyFormatter.swift

# Fix View files
echo "📝 Fixing View files..."
sed -i.bak 's/currency\.rawValue/currency.code/g' Views/CurrencyExpenseListView.swift
sed -i.bak 's/initialCurrency\.rawValue/initialCurrency.code/g' Views/MultiCurrencyTabbedView.swift
sed -i.bak 's/Currency\.allCases/Currency.common/g' Views/SettingsView.swift
sed -i.bak 's/Currency\.allCases/Currency.common/g' Views/CurrencyOnboardingView.swift

# Fix SiriKit
echo "📝 Fixing SiriKit files..."
sed -i.bak 's/\.rawValue/.code/g' SiriKit/ShortcutsManager.swift 2>/dev/null || true

# Remove backup files
echo "🧹 Cleaning up backup files..."
find . -name "*.bak" -delete

echo "✅ All fixes applied successfully!"
echo ""
echo "📋 Summary of changes:"
echo "  - Currency(rawValue:) → Currency.from(isoCode:)"
echo "  - currency.rawValue → currency.code"
echo "  - Currency.allCases → Currency.common (for UI)"
echo "  - Currency.allCases → Currency.all (for iteration)"
echo ""
echo "🔄 Please rebuild your project in Xcode"
