package com.justspent.app.ui.expenses

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.justspent.app.data.model.Currency

/**
 * Simple expense list view for when only one currency exists
 * No tabs needed - just shows the single currency list
 *
 * @param currency The single currency to display
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SingleCurrencyScreen(currency: Currency) {
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
    ) { _ ->
        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            // Simply show the currency-filtered list
            CurrencyExpenseListScreen(currency = currency)
        }
    }
}
