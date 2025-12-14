package com.justspent.expense.ui.expenses

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.text.KeyboardOptions
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
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.justspent.expense.data.model.Currency
import com.justspent.expense.data.model.Expense
import com.justspent.expense.ui.components.FilterStrip
import com.justspent.expense.utils.DateFilter
import com.justspent.expense.utils.DateFilterUtils
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime

/**
 * Reusable expense list screen filtered by currency with pagination
 * Used by both SingleCurrencyScreen and MultiCurrencyTabbedScreen
 *
 * Implements lazy loading pagination:
 * - Loads 20 items per page
 * - Automatically loads more when scrolling near bottom
 * - Shows loading indicator while fetching
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
    // Use pagination state instead of regular UI state
    val paginationState by viewModel.paginationState.collectAsState()
    val expenses = paginationState.loadedExpenses
    val isLoading = paginationState.isLoading
    val hasMore = paginationState.hasMore

    // LazyListState for scroll detection
    val listState = rememberLazyListState()

    // Load first page when currency or date filter changes
    LaunchedEffect(currency.code, dateFilter) {
        viewModel.loadFirstPage(
            currency = currency.code,
            dateFilter = dateFilter
        )
    }

    // Detect when scrolling near bottom and load more
    LaunchedEffect(listState) {
        snapshotFlow { listState.layoutInfo.visibleItemsInfo }
            .collect { visibleItems ->
                if (!isLoading && hasMore && visibleItems.isNotEmpty()) {
                    val lastVisibleItem = visibleItems.last()
                    val totalItems = listState.layoutInfo.totalItemsCount

                    // Load next page when within 5 items of the end (prefetch distance)
                    if (lastVisibleItem.index >= totalItems - 5) {
                        viewModel.loadNextPage()
                    }
                }
            }
    }

    // Expense List - wrap in key() to force recreation when currency changes
    key(currency.code) {
        Column(modifier = Modifier.fillMaxSize()) {
            // Show filter strip only when there are expenses
            if (expenses.isNotEmpty()) {
                FilterStrip(
                    selectedFilter = dateFilter,
                    onFilterSelected = onDateFilterChanged,
                    modifier = Modifier.testTag("expense_filter_strip")
                )
            }

            if (expenses.isEmpty() && !isLoading) {
                // Empty state (no expenses loaded)
                EmptyCurrencyState(currency = currency)
            } else {
                LazyColumn(
                    state = listState,
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(
                        items = expenses,
                        key = { expense -> expense.id }
                    ) { expense ->
                        CurrencyExpenseRow(
                            expense = expense,
                            currency = currency,
                            onDelete = { viewModel.deleteExpense(expense) },
                            onEdit = { viewModel.updateExpense(it) }
                        )
                    }

                    // Loading indicator at bottom
                    if (isLoading) {
                        item {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(16.dp),
                                contentAlignment = Alignment.Center
                            ) {
                                CircularProgressIndicator(
                                    modifier = Modifier.size(32.dp)
                                )
                            }
                        }
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
    onDelete: (Expense) -> Unit,
    onEdit: (Expense) -> Unit
) {
    // State for delete confirmation dialog
    var showDeleteConfirmation by remember { mutableStateOf(false) }
    var pendingSwipeDelete by remember { mutableStateOf(false) }

    // State for edit dialog
    var showEditDialog by remember { mutableStateOf(false) }

    val dismissState = rememberDismissState(
        confirmValueChange = { dismissValue ->
            when (dismissValue) {
                DismissValue.DismissedToEnd -> {
                    // Swipe right - Edit
                    showEditDialog = true
                    false // Prevent auto-dismiss
                }
                DismissValue.DismissedToStart -> {
                    // Swipe left - Delete
                    pendingSwipeDelete = true
                    showDeleteConfirmation = true
                    false // Prevent auto-dismiss
                }
                else -> false
            }
        }
    )

    // Reset dismiss state when dialogs are dismissed
    LaunchedEffect(showDeleteConfirmation, showEditDialog) {
        if (!showDeleteConfirmation && pendingSwipeDelete) {
            pendingSwipeDelete = false
            dismissState.reset()
        }
        if (!showEditDialog) {
            dismissState.reset()
        }
    }

    SwipeToDismiss(
        state = dismissState,
        background = {
            val backgroundColor = when (dismissState.dismissDirection) {
                DismissDirection.StartToEnd -> MaterialTheme.colorScheme.primaryContainer
                DismissDirection.EndToStart -> MaterialTheme.colorScheme.errorContainer
                else -> Color.Transparent
            }

            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(backgroundColor),
                contentAlignment = when (dismissState.dismissDirection) {
                    DismissDirection.StartToEnd -> Alignment.CenterStart
                    else -> Alignment.CenterEnd
                }
            ) {
                if (dismissState.dismissDirection != null) {
                    val (text, color) = when (dismissState.dismissDirection) {
                        DismissDirection.StartToEnd -> "Edit" to MaterialTheme.colorScheme.onPrimaryContainer
                        else -> "Delete" to MaterialTheme.colorScheme.onErrorContainer
                    }
                    Text(
                        text = text,
                        color = color,
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

    // Edit Expense Dialog
    if (showEditDialog) {
        EditExpenseDialog(
            expense = expense,
            currency = currency,
            onDismiss = { showEditDialog = false },
            onSave = { updatedExpense ->
                onEdit(updatedExpense)
                showEditDialog = false
            }
        )
    }
}

/**
 * Dialog for editing expense category and amount
 * Currency is not editable (displayed as read-only)
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun EditExpenseDialog(
    expense: Expense,
    currency: Currency,
    onDismiss: () -> Unit,
    onSave: (Expense) -> Unit
) {
    // Available categories (matching data-models-spec.md)
    val categories = listOf(
        "Food & Dining",
        "Grocery",
        "Transportation",
        "Shopping",
        "Entertainment",
        "Bills & Utilities",
        "Healthcare",
        "Education",
        "Other"
    )

    // Editable fields
    var selectedCategory by remember { mutableStateOf(expense.category) }
    var amountText by remember { mutableStateOf(expense.amount.toPlainString()) }
    var expanded by remember { mutableStateOf(false) }

    // Validation
    val isValidAmount = remember(amountText) {
        try {
            val amount = amountText.toBigDecimalOrNull()
            amount != null && amount > java.math.BigDecimal.ZERO
        } catch (e: Exception) {
            false
        }
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        modifier = Modifier.semantics { testTag = "edit_dialog" },
        title = { Text("Edit Expense") },
        text = {
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Currency (Read-only)
                Column {
                    Text(
                        text = "Currency",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = currency.symbol,
                            style = MaterialTheme.typography.titleLarge
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = currency.displayName,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.weight(1f))
                        Text(
                            text = "Not editable",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                // Amount
                OutlinedTextField(
                    value = amountText,
                    onValueChange = { amountText = it },
                    label = { Text("Amount") },
                    modifier = Modifier
                        .fillMaxWidth()
                        .semantics { testTag = "amount_field" },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    isError = !isValidAmount && amountText.isNotEmpty(),
                    supportingText = {
                        if (!isValidAmount && amountText.isNotEmpty()) {
                            Text("Please enter a valid amount")
                        }
                    }
                )

                // Category Dropdown
                ExposedDropdownMenuBox(
                    expanded = expanded,
                    onExpandedChange = { expanded = it },
                    modifier = Modifier.semantics { testTag = "category_dropdown" }
                ) {
                    OutlinedTextField(
                        value = selectedCategory,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Category") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
                        modifier = Modifier
                            .menuAnchor()
                            .fillMaxWidth()
                    )
                    ExposedDropdownMenu(
                        expanded = expanded,
                        onDismissRequest = { expanded = false }
                    ) {
                        categories.forEach { category ->
                            DropdownMenuItem(
                                text = { Text(category) },
                                onClick = {
                                    selectedCategory = category
                                    expanded = false
                                },
                                contentPadding = ExposedDropdownMenuDefaults.ItemContentPadding
                            )
                        }
                    }
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    val amount = amountText.toBigDecimalOrNull() ?: return@TextButton
                    val updatedExpense = expense.copy(
                        amount = amount,
                        category = selectedCategory,
                        updatedAt = Clock.System.now()
                            .toLocalDateTime(TimeZone.currentSystemDefault())
                    )
                    onSave(updatedExpense)
                },
                enabled = isValidAmount
            ) {
                Text("Save")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}
