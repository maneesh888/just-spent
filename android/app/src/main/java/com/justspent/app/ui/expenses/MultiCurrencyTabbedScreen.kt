package com.justspent.app.ui.expenses

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.justspent.app.data.model.Currency

/**
 * Tabbed interface for multiple currency expense tracking
 * Shows scrollable tabs at top for switching between currencies
 *
 * @param currencies List of currencies with expenses
 * @param defaultCurrency User's preferred default currency
 */
@Composable
fun MultiCurrencyTabbedScreen(
    currencies: List<Currency>,
    defaultCurrency: Currency
) {
    // Sort currencies alphabetically
    val sortedCurrencies = remember(currencies) {
        currencies.sortedBy { it.displayName }
    }

    // Set initial selected currency to default if available
    val initialCurrency = remember(sortedCurrencies, defaultCurrency) {
        sortedCurrencies.find { it == defaultCurrency } ?: sortedCurrencies.firstOrNull() ?: Currency.AED
    }

    var selectedCurrency by remember { mutableStateOf(initialCurrency) }

    Column(modifier = Modifier.fillMaxSize()) {
        // Currency Tab Bar
        CurrencyTabBar(
            currencies = sortedCurrencies,
            selectedCurrency = selectedCurrency,
            onCurrencySelected = { selectedCurrency = it }
        )

        // Selected Currency Expense List
        CurrencyExpenseListScreen(currency = selectedCurrency)
    }
}

/**
 * Horizontal scrollable tab bar for currency selection
 */
@Composable
private fun CurrencyTabBar(
    currencies: List<Currency>,
    selectedCurrency: Currency,
    onCurrencySelected: (Currency) -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        tonalElevation = 3.dp,
        shadowElevation = 2.dp
    ) {
        ScrollableTabRow(
            selectedTabIndex = currencies.indexOf(selectedCurrency).coerceAtLeast(0),
            edgePadding = 16.dp,
            containerColor = MaterialTheme.colorScheme.surface,
            contentColor = MaterialTheme.colorScheme.onSurface,
            indicator = { _ ->
                if (currencies.indexOf(selectedCurrency) >= 0) {
                    TabRowDefaults.Indicator(
                        modifier = Modifier.fillMaxWidth(),
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }
        ) {
            currencies.forEach { currency ->
                CurrencyTab(
                    currency = currency,
                    isSelected = currency == selectedCurrency,
                    onClick = { onCurrencySelected(currency) }
                )
            }
        }
    }
}

/**
 * Individual currency tab
 */
@Composable
private fun CurrencyTab(
    currency: Currency,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Tab(
        selected = isSelected,
        onClick = onClick,
        modifier = Modifier.padding(horizontal = 4.dp)
    ) {
        Column(
            modifier = Modifier.padding(vertical = 12.dp, horizontal = 16.dp)
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Text(
                    text = currency.symbol,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                    color = if (isSelected)
                        MaterialTheme.colorScheme.primary
                    else
                        MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = currency.code,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                    color = if (isSelected)
                        MaterialTheme.colorScheme.primary
                    else
                        MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}
