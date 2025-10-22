package com.justspent.app.ui.expenses

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.justspent.app.data.model.Currency
import androidx.compose.material3.TabRowDefaults.tabIndicatorOffset

/**
 * Tabbed interface for multiple currency expense tracking
 * Shows scrollable tabs at top for switching between currencies
 *
 * @param currencies List of currencies with expenses
 * @param defaultCurrency User's preferred default currency
 */
@OptIn(ExperimentalMaterial3Api::class)
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

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text("Just Spent")
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                    titleContentColor = MaterialTheme.colorScheme.onSurface
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
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
            edgePadding = 0.dp,
            containerColor = MaterialTheme.colorScheme.surface,
            contentColor = MaterialTheme.colorScheme.onSurface,
            indicator = { tabPositions ->
                val selectedIndex = currencies.indexOf(selectedCurrency)
                if (selectedIndex >= 0 && selectedIndex < tabPositions.size) {
                    TabRowDefaults.Indicator(
                        modifier = Modifier.tabIndicatorOffset(tabPositions[selectedIndex]),
                        color = MaterialTheme.colorScheme.primary,
                        height = 3.dp
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
        modifier = Modifier.padding(horizontal = 8.dp),
        selectedContentColor = MaterialTheme.colorScheme.primary,
        unselectedContentColor = MaterialTheme.colorScheme.onSurface
    ) {
        Row(
            modifier = Modifier.padding(vertical = 12.dp, horizontal = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Text(
                text = currency.symbol,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium
            )
            Text(
                text = currency.code,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal
            )
        }
    }
}
