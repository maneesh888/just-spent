package com.justspent.app.ui.expenses

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.key
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.justspent.app.data.model.Currency
import com.justspent.app.data.model.Expense

/**
 * Reusable expense list screen filtered by currency
 * Used by both SingleCurrencyScreen and MultiCurrencyTabbedScreen
 *
 * @param currency Currency to filter expenses by
 * @param viewModel Expense list view model
 */
@Composable
fun CurrencyExpenseListScreen(
    currency: Currency,
    viewModel: ExpenseListViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val expenses = uiState.expenses

    // Filter expenses by currency - explicitly depend on both expenses and currency
    // Use remember with both keys to ensure proper recomposition
    val currencyExpenses = remember(expenses, currency.code) {
        expenses.filter { it.currency == currency.code }
    }

    // Expense List - wrap in key() to force recreation when currency changes
    key(currency.code) {
        if (currencyExpenses.isEmpty()) {
            // Empty state for this currency
            EmptyCurrencyState(currency = currency)
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(vertical = 8.dp)
            ) {
                items(
                    items = currencyExpenses,
                    key = { expense -> expense.id }
                ) { expense ->
                    CurrencyExpenseRow(
                        expense = expense,
                        currency = currency,
                        onDelete = { viewModel.deleteExpense(expense) }
                    )
                }
            }
        }
    }
}

/**
 * Empty state for a specific currency
 */
@Composable
private fun EmptyCurrencyState(currency: Currency) {
    @Suppress("UNUSED_PARAMETER")
    Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(32.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Icon(
                imageVector = Icons.Default.ShoppingCart,
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
            )

            Text(
                text = "No ${currency.displayName} Expenses",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Text(
                text = "Tap the microphone button to add an expense",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
            )
        }
    }
}

/**
 * Expense row view without currency badge (currency is known from context)
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun CurrencyExpenseRow(
    expense: Expense,
    currency: Currency,
    onDelete: (Expense) -> Unit
) {
    val dismissState = rememberDismissState(
        confirmValueChange = { dismissValue ->
            if (dismissValue == DismissValue.DismissedToStart || dismissValue == DismissValue.DismissedToEnd) {
                onDelete(expense)
                true
            } else {
                false
            }
        }
    )

    SwipeToDismiss(
        state = dismissState,
        background = {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                contentAlignment = when (dismissState.dismissDirection) {
                    DismissDirection.StartToEnd -> Alignment.CenterStart
                    else -> Alignment.CenterEnd
                }
            ) {
                if (dismissState.dismissDirection != null) {
                    Text(
                        text = "Delete",
                        color = MaterialTheme.colorScheme.onErrorContainer,
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium
                    )
                }
            }
        },
        dismissContent = {
            ExpenseRow(
                expense = expense,
                onDelete = { onDelete(expense) }
            )
        }
    )
}
