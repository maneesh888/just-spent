package com.justspent.expense.ui.expenses

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.key
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.justspent.expense.data.model.Currency
import com.justspent.expense.data.model.Expense
import com.justspent.expense.ui.components.FilterStrip
import com.justspent.expense.utils.DateFilter
import com.justspent.expense.utils.DateFilterUtils

/**
 * Reusable expense list screen filtered by currency
 * Used by both SingleCurrencyScreen and MultiCurrencyTabbedScreen
 *
 * @param currency Currency to filter expenses by
 * @param dateFilter Current date filter selection
 * @param onDateFilterChanged Callback when date filter is changed
 * @param viewModel Expense list view model
 */
@Composable
fun CurrencyExpenseListScreen(
    currency: Currency,
    dateFilter: DateFilter,
    onDateFilterChanged: (DateFilter) -> Unit,
    viewModel: ExpenseListViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val expenses = uiState.expenses

    // Filter expenses by currency - explicitly depend on both expenses and currency
    // Use remember with both keys to ensure proper recomposition
    val currencyExpenses = remember(expenses, currency.code) {
        expenses.filter { it.currency == currency.code }
    }

    // Apply date filter to currency expenses
    val filteredExpenses = remember(currencyExpenses, dateFilter) {
        currencyExpenses.filter { expense ->
            DateFilterUtils.isDateInFilter(expense.transactionDate, dateFilter)
        }
    }

    // Expense List - wrap in key() to force recreation when currency changes
    key(currency.code) {
        Column(modifier = Modifier.fillMaxSize()) {
            // Show filter strip only when there are expenses
            if (currencyExpenses.isNotEmpty()) {
                FilterStrip(
                    selectedFilter = dateFilter,
                    onFilterSelected = onDateFilterChanged,
                    modifier = Modifier.testTag("expense_filter_strip")
                )
            }

            if (currencyExpenses.isEmpty()) {
                // Empty state for this currency (no expenses at all)
                EmptyCurrencyState(currency = currency)
            } else if (filteredExpenses.isEmpty()) {
                // Empty state for filtered results
                EmptyFilterState(filter = dateFilter)
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(
                        items = filteredExpenses,
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
}

/**
 * Empty state for a specific currency
 */
@Composable
private fun EmptyCurrencyState(currency: Currency) {
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
 * Empty state for filtered results
 */
@Composable
private fun EmptyFilterState(filter: DateFilter) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(32.dp)
            .testTag("empty_filter_state"),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Icon(
                imageVector = Icons.Default.DateRange,
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
            )

            Text(
                text = "No Expenses for ${filter.displayName}",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Text(
                text = "Try selecting a different time period",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
            )
        }
    }
}

/**
 * Expense row view without currency badge (currency is known from context)
 * Shows confirmation dialog before deleting (both swipe and button tap)
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun CurrencyExpenseRow(
    expense: Expense,
    currency: Currency,
    onDelete: (Expense) -> Unit
) {
    // State for delete confirmation dialog
    var showDeleteConfirmation by remember { mutableStateOf(false) }
    var pendingSwipeDelete by remember { mutableStateOf(false) }

    val dismissState = rememberDismissState(
        confirmValueChange = { dismissValue ->
            if (dismissValue == DismissValue.DismissedToStart || dismissValue == DismissValue.DismissedToEnd) {
                // Don't delete immediately - show confirmation dialog
                pendingSwipeDelete = true
                showDeleteConfirmation = true
                false // Return false to prevent auto-dismiss, we'll handle it after confirmation
            } else {
                false
            }
        }
    )

    // Reset dismiss state when dialog is dismissed without deleting
    LaunchedEffect(showDeleteConfirmation) {
        if (!showDeleteConfirmation && pendingSwipeDelete) {
            pendingSwipeDelete = false
            dismissState.reset()
        }
    }

    SwipeToDismiss(
        state = dismissState,
        background = {
            Box(
                modifier = Modifier.fillMaxSize(),
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
                        fontWeight = FontWeight.Medium,
                        modifier = Modifier.padding(horizontal = 16.dp)
                    )
                }
            }
        },
        dismissContent = {
            ExpenseRow(
                expense = expense,
                onDelete = {
                    // Button tap delete - also show confirmation
                    showDeleteConfirmation = true
                },
                modifier = Modifier.semantics { testTag = "expense_row" }
            )
        }
    )

    // Delete Confirmation Dialog
    if (showDeleteConfirmation) {
        AlertDialog(
            onDismissRequest = {
                showDeleteConfirmation = false
                pendingSwipeDelete = false
            },
            modifier = Modifier.semantics { testTag = "delete_confirmation_dialog" },
            title = {
                Text("Delete Expense")
            },
            text = {
                Text("Are you sure you want to delete this expense?")
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        onDelete(expense)
                        showDeleteConfirmation = false
                        pendingSwipeDelete = false
                    }
                ) {
                    Text("Delete")
                }
            },
            dismissButton = {
                TextButton(
                    onClick = {
                        showDeleteConfirmation = false
                        pendingSwipeDelete = false
                    }
                ) {
                    Text("Cancel")
                }
            }
        )
    }
}
