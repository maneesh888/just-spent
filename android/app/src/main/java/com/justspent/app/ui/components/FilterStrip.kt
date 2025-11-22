package com.justspent.app.ui.components

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.justspent.app.utils.DateFilter
import com.justspent.app.utils.DateFilterUtils
import java.time.LocalDate
import java.time.format.DateTimeFormatter

/**
 * A horizontal strip of filter chips for filtering expenses by date
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FilterStrip(
    selectedFilter: DateFilter,
    onFilterSelected: (DateFilter) -> Unit,
    modifier: Modifier = Modifier
) {
    var showCustomDialog by remember { mutableStateOf(false) }
    var customStartDate by remember { mutableStateOf(LocalDate.now().minusDays(6)) }
    var customEndDate by remember { mutableStateOf(LocalDate.now()) }

    // Initialize custom dates if already selected
    LaunchedEffect(selectedFilter) {
        if (selectedFilter is DateFilter.Custom) {
            customStartDate = selectedFilter.start
            customEndDate = selectedFilter.end
        }
    }

    val presetFilters = listOf(
        DateFilter.All,
        DateFilter.Today,
        DateFilter.Week,
        DateFilter.Month
    )

    Surface(
        modifier = modifier
            .fillMaxWidth()
            .testTag("filter_strip"),
        color = MaterialTheme.colorScheme.surface
    ) {
        LazyRow(
            modifier = Modifier.padding(vertical = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            contentPadding = PaddingValues(horizontal = 16.dp)
        ) {
            // Preset filter chips
            items(presetFilters) { filter ->
                FilterChip(
                    selected = selectedFilter == filter,
                    onClick = { onFilterSelected(filter) },
                    label = { Text(filter.displayName) },
                    modifier = Modifier
                        .testTag("filter_chip_${filter.displayName.lowercase()}")
                        .semantics {
                            contentDescription = "${filter.displayName} filter"
                        }
                )
            }

            // Custom filter chip
            item {
                val customLabel = when (selectedFilter) {
                    is DateFilter.Custom -> selectedFilter.customRangeDisplayString ?: "Custom"
                    else -> "Custom"
                }

                FilterChip(
                    selected = selectedFilter is DateFilter.Custom,
                    onClick = { showCustomDialog = true },
                    label = { Text(customLabel) },
                    modifier = Modifier
                        .testTag("filter_chip_custom")
                        .semantics {
                            contentDescription = "Custom date range filter"
                        }
                )
            }
        }
    }

    // Custom date range dialog
    if (showCustomDialog) {
        CustomDateRangeDialog(
            initialStartDate = customStartDate,
            initialEndDate = customEndDate,
            onDismiss = { showCustomDialog = false },
            onApply = { start, end ->
                customStartDate = start
                customEndDate = end
                onFilterSelected(DateFilter.Custom(start, end))
                showCustomDialog = false
            }
        )
    }
}

/**
 * Dialog for selecting a custom date range
 */
@Composable
fun CustomDateRangeDialog(
    initialStartDate: LocalDate,
    initialEndDate: LocalDate,
    onDismiss: () -> Unit,
    onApply: (LocalDate, LocalDate) -> Unit
) {
    var startDate by remember { mutableStateOf(initialStartDate) }
    var endDate by remember { mutableStateOf(initialEndDate) }
    var validationError by remember { mutableStateOf<String?>(null) }
    var showStartDatePicker by remember { mutableStateOf(false) }
    var showEndDatePicker by remember { mutableStateOf(false) }

    val dateFormatter = remember { DateTimeFormatter.ofPattern("MMM d, yyyy") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Custom Date Range") },
        text = {
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Start Date
                Column {
                    Text(
                        text = "Start Date",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    OutlinedButton(
                        onClick = { showStartDatePicker = true },
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("custom_start_date_button")
                    ) {
                        Text(startDate.format(dateFormatter))
                    }
                }

                // End Date
                Column {
                    Text(
                        text = "End Date",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    OutlinedButton(
                        onClick = { showEndDatePicker = true },
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("custom_end_date_button")
                    ) {
                        Text(endDate.format(dateFormatter))
                    }
                }

                // Validation error
                validationError?.let { error ->
                    Text(
                        text = error,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.error,
                        modifier = Modifier.testTag("validation_error")
                    )
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    val validation = DateFilterUtils.validateCustomRange(startDate, endDate)
                    if (validation.isValid) {
                        validationError = null
                        onApply(startDate, endDate)
                    } else {
                        validationError = validation.firstError
                    }
                },
                modifier = Modifier.testTag("apply_custom_filter_button")
            ) {
                Text("Apply")
            }
        },
        dismissButton = {
            TextButton(
                onClick = onDismiss,
                modifier = Modifier.testTag("cancel_custom_filter_button")
            ) {
                Text("Cancel")
            }
        }
    )

    // Start Date Picker Dialog
    if (showStartDatePicker) {
        DatePickerDialog(
            selectedDate = startDate,
            onDateSelected = { date ->
                startDate = date
                showStartDatePicker = false
            },
            onDismiss = { showStartDatePicker = false },
            maxDate = LocalDate.now()
        )
    }

    // End Date Picker Dialog
    if (showEndDatePicker) {
        DatePickerDialog(
            selectedDate = endDate,
            onDateSelected = { date ->
                endDate = date
                showEndDatePicker = false
            },
            onDismiss = { showEndDatePicker = false },
            maxDate = LocalDate.now()
        )
    }
}

/**
 * Material 3 Date Picker Dialog
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DatePickerDialog(
    selectedDate: LocalDate,
    onDateSelected: (LocalDate) -> Unit,
    onDismiss: () -> Unit,
    maxDate: LocalDate = LocalDate.now()
) {
    val datePickerState = rememberDatePickerState(
        initialSelectedDateMillis = selectedDate.toEpochDay() * 24 * 60 * 60 * 1000
    )

    DatePickerDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            TextButton(
                onClick = {
                    datePickerState.selectedDateMillis?.let { millis ->
                        val date = LocalDate.ofEpochDay(millis / (24 * 60 * 60 * 1000))
                        // Validate that date is not in the future
                        if (!date.isAfter(maxDate)) {
                            onDateSelected(date)
                        } else {
                            // If future date selected, use maxDate instead
                            onDateSelected(maxDate)
                        }
                    }
                }
            ) {
                Text("OK")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    ) {
        DatePicker(state = datePickerState)
    }
}
