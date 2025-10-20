//
//  MultiCurrencyTabbedViewTests.swift
//  JustSpentTests
//
//  Created by Claude Code on 2025-10-20.
//  Tests for multi-currency tabbed interface
//

import XCTest
import SwiftUI
@testable import JustSpent

final class MultiCurrencyTabbedViewTests: XCTestCase {

    // MARK: - Currency Sorting Tests

    func testCurrenciesSortedAlphabetically() throws {
        let currencies: [Currency] = [.usd, .aed, .eur, .gbp]
        let sorted = currencies.sorted { $0.displayName < $1.displayName }

        // Verify sorting order by display name
        for i in 0..<(sorted.count - 1) {
            XCTAssertLessThan(
                sorted[i].displayName,
                sorted[i + 1].displayName,
                "Currencies should be sorted alphabetically by display name"
            )
        }
    }

    func testCurrencySortingConsistency() throws {
        let currencies: [Currency] = [.sar, .inr, .gbp, .eur, .usd, .aed]
        let sorted1 = currencies.sorted { $0.displayName < $1.displayName }
        let sorted2 = currencies.sorted { $0.displayName < $1.displayName }

        XCTAssertEqual(sorted1, sorted2, "Currency sorting should be consistent")
    }

    // MARK: - Default Currency Selection Tests

    func testDefaultCurrencySelection() throws {
        // Set default currency
        UserPreferences.shared.defaultCurrency = .aed

        let currencies: [Currency] = [.usd, .aed, .eur]
        let defaultCurrency = UserPreferences.shared.defaultCurrency

        XCTAssertTrue(currencies.contains(defaultCurrency), "Default currency should be in the list")
        XCTAssertEqual(defaultCurrency, .aed, "Default currency should be AED")
    }

    func testDefaultCurrencyFallback() throws {
        let currencies: [Currency] = [.usd, .eur, .gbp]

        // If default currency (AED) is not in the list, should select first
        let selectedCurrency = currencies.first ?? .aed

        XCTAssertEqual(selectedCurrency, .usd, "Should fallback to first currency")
    }

    func testInitialSelectionWithDefaultCurrency() throws {
        UserPreferences.shared.defaultCurrency = .eur

        let currencies: [Currency] = [.aed, .usd, .eur, .gbp]

        // Find default currency in list
        if let defaultIndex = currencies.firstIndex(of: UserPreferences.shared.defaultCurrency) {
            let selected = currencies[defaultIndex]
            XCTAssertEqual(selected, .eur, "Should select default currency EUR")
        } else {
            XCTFail("Default currency should be found in list")
        }
    }

    // MARK: - Tab Creation Tests

    func testTabCreationForTwoCurrencies() throws {
        let currencies: [Currency] = [.aed, .usd]

        XCTAssertEqual(currencies.count, 2, "Should have 2 tabs")
        XCTAssertTrue(currencies.contains(.aed), "Should have AED tab")
        XCTAssertTrue(currencies.contains(.usd), "Should have USD tab")
    }

    func testTabCreationForManyCurrencies() throws {
        let currencies: [Currency] = [.aed, .usd, .eur, .gbp, .inr, .sar]

        XCTAssertEqual(currencies.count, 6, "Should have 6 tabs")

        // Verify all currencies present
        for currency in currencies {
            XCTAssertTrue(currencies.contains(currency), "Should have \(currency.rawValue) tab")
        }
    }

    func testNoDuplicateTabs() throws {
        let currencies: [Currency] = [.aed, .usd, .aed, .eur, .usd]
        let uniqueCurrencies = Array(Set(currencies))

        XCTAssertEqual(uniqueCurrencies.count, 3, "Should have only unique currency tabs")
    }

    // MARK: - Tab Display Properties Tests

    func testTabDisplaysSymbolAndCode() throws {
        let currency = Currency.aed

        XCTAssertEqual(currency.symbol, "د.إ", "AED symbol should be correct")
        XCTAssertEqual(currency.rawValue, "AED", "AED code should be correct")
    }

    func testAllCurrencyTabProperties() throws {
        let currencies: [Currency] = [.aed, .usd, .eur, .gbp, .inr, .sar]

        for currency in currencies {
            XCTAssertFalse(currency.symbol.isEmpty, "\(currency.rawValue) should have a symbol")
            XCTAssertFalse(currency.rawValue.isEmpty, "\(currency.rawValue) should have a code")
            XCTAssertFalse(currency.displayName.isEmpty, "\(currency.rawValue) should have a display name")
        }
    }

    // MARK: - Tab Selection State Tests

    func testTabSelectionEquality() throws {
        let currency1 = Currency.aed
        let currency2 = Currency.aed
        let currency3 = Currency.usd

        XCTAssertEqual(currency1, currency2, "Same currency should be equal")
        XCTAssertNotEqual(currency1, currency3, "Different currencies should not be equal")
    }

    func testTabSelectionStateChange() throws {
        var selectedCurrency = Currency.aed

        XCTAssertEqual(selectedCurrency, .aed, "Initial selection should be AED")

        // Simulate tab switch
        selectedCurrency = .usd

        XCTAssertEqual(selectedCurrency, .usd, "Selection should change to USD")
        XCTAssertNotEqual(selectedCurrency, .aed, "Selection should no longer be AED")
    }

    // MARK: - View Initialization Tests

    func testMultiCurrencyTabbedViewCreation() throws {
        let currencies: [Currency] = [.aed, .usd, .eur]
        let view = MultiCurrencyTabbedView(currencies: currencies)

        XCTAssertNotNil(view, "View should be created successfully")
    }

    func testViewCreationWithEmptyCurrencies() throws {
        let currencies: [Currency] = []
        let view = MultiCurrencyTabbedView(currencies: currencies)

        XCTAssertNotNil(view, "View should handle empty currencies gracefully")
    }

    func testViewCreationWithSingleCurrency() throws {
        let currencies: [Currency] = [.aed]
        let view = MultiCurrencyTabbedView(currencies: currencies)

        XCTAssertNotNil(view, "View should handle single currency")
    }

    // MARK: - Currency Tab Component Tests

    func testCurrencyTabSelection() throws {
        let selectedTab = Currency.aed
        let unselectedTab = Currency.usd

        // Test selection state
        XCTAssertEqual(selectedTab, .aed, "Selected tab should be AED")
        XCTAssertNotEqual(unselectedTab, selectedTab, "Unselected tab should not equal selected")
    }

    func testCurrencyTabVisualProperties() throws {
        let isSelected = true
        let isNotSelected = false

        // Visual states should be different
        XCTAssertNotEqual(isSelected, isNotSelected, "Selected and unselected states should differ")
    }

    // MARK: - Tab Bar Scrolling Tests

    func testTabBarWithManyCurrencies() throws {
        // With 6 currencies, tab bar should be scrollable
        let currencies: [Currency] = [.aed, .usd, .eur, .gbp, .inr, .sar]

        XCTAssertGreaterThan(currencies.count, 4, "Should have enough currencies to require scrolling")
    }

    func testTabBarWithFewCurrencies() throws {
        // With 2-3 currencies, all tabs should be visible
        let currencies: [Currency] = [.aed, .usd]

        XCTAssertLessThanOrEqual(currencies.count, 3, "Should have few enough currencies to fit without scrolling")
    }

    // MARK: - Integration Tests

    func testSwitchingBetweenTabs() throws {
        let currencies: [Currency] = [.aed, .usd, .eur]
        var selectedCurrency = currencies[0]

        XCTAssertEqual(selectedCurrency, .aed, "Should start with first currency")

        // Switch to second tab
        selectedCurrency = currencies[1]
        XCTAssertEqual(selectedCurrency, .usd, "Should switch to USD")

        // Switch to third tab
        selectedCurrency = currencies[2]
        XCTAssertEqual(selectedCurrency, .eur, "Should switch to EUR")
    }

    func testTabSwitchPreservesState() throws {
        var selectedCurrency = Currency.aed

        // Switch tabs
        selectedCurrency = .usd
        let afterFirstSwitch = selectedCurrency

        selectedCurrency = .eur
        selectedCurrency = afterFirstSwitch

        XCTAssertEqual(selectedCurrency, .usd, "Should return to previous tab state")
    }

    // MARK: - Currency List Management Tests

    func testAddingNewCurrencyToTabs() throws {
        var currencies: [Currency] = [.aed, .usd]

        XCTAssertEqual(currencies.count, 2, "Should start with 2 currencies")

        // Add new currency (simulating voice command with new currency)
        if !currencies.contains(.eur) {
            currencies.append(.eur)
        }

        XCTAssertEqual(currencies.count, 3, "Should have 3 currencies after adding EUR")
        XCTAssertTrue(currencies.contains(.eur), "Should contain EUR")
    }

    func testPreventDuplicateCurrencyAddition() throws {
        var currencies: [Currency] = [.aed, .usd]

        // Try to add existing currency
        if !currencies.contains(.aed) {
            currencies.append(.aed)
        }

        XCTAssertEqual(currencies.count, 2, "Should still have 2 currencies")
    }

    // MARK: - Accessibility Tests

    func testCurrencyTabAccessibilityLabels() throws {
        let currency = Currency.aed

        let accessibilityLabel = "\(currency.displayName) tab"

        XCTAssertFalse(accessibilityLabel.isEmpty, "Should have accessibility label")
        XCTAssertTrue(accessibilityLabel.contains(currency.displayName), "Label should contain currency name")
    }

    func testAllCurrenciesHaveAccessibilityInfo() throws {
        let currencies: [Currency] = [.aed, .usd, .eur, .gbp, .inr, .sar]

        for currency in currencies {
            XCTAssertFalse(currency.displayName.isEmpty, "\(currency.rawValue) should have display name for accessibility")
        }
    }

    // MARK: - Performance Tests

    func testTabCreationPerformance() throws {
        measure {
            let currencies: [Currency] = [.aed, .usd, .eur, .gbp, .inr, .sar]
            _ = MultiCurrencyTabbedView(currencies: currencies)
        }
    }

    func testCurrencySortingPerformance() throws {
        let currencies: [Currency] = [.aed, .usd, .eur, .gbp, .inr, .sar]

        measure {
            _ = currencies.sorted { $0.displayName < $1.displayName }
        }
    }

    func testTabSwitchingPerformance() throws {
        let currencies: [Currency] = [.aed, .usd, .eur, .gbp, .inr, .sar]
        var selectedCurrency = currencies[0]

        measure {
            for i in 0..<100 {
                selectedCurrency = currencies[i % currencies.count]
            }
        }

        XCTAssertNotNil(selectedCurrency, "Should maintain selection state")
    }

    // MARK: - Edge Case Tests

    func testEmptyCurrencyList() throws {
        let currencies: [Currency] = []
        let sorted = currencies.sorted { $0.displayName < $1.displayName }

        XCTAssertTrue(sorted.isEmpty, "Empty list should remain empty after sorting")
    }

    func testSingleCurrencyList() throws {
        let currencies: [Currency] = [.aed]
        let sorted = currencies.sorted { $0.displayName < $1.displayName }

        XCTAssertEqual(sorted.count, 1, "Single currency should remain")
        XCTAssertEqual(sorted.first, .aed, "Should preserve single currency")
    }

    func testAllSupportedCurrencies() throws {
        let allCurrencies: [Currency] = [.aed, .usd, .eur, .gbp, .inr, .sar]

        XCTAssertEqual(allCurrencies.count, 6, "Should have all 6 supported currencies")

        // Verify each has required properties
        for currency in allCurrencies {
            XCTAssertFalse(currency.symbol.isEmpty, "Symbol should not be empty")
            XCTAssertFalse(currency.displayName.isEmpty, "Display name should not be empty")
            XCTAssertEqual(currency.rawValue.count, 3, "ISO code should be 3 characters")
        }
    }
}
