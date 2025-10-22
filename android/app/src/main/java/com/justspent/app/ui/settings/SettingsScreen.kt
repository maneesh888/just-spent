package com.justspent.app.ui.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.justspent.app.data.model.Currency
import com.justspent.app.data.model.User
import java.time.format.DateTimeFormatter

/**
 * Settings Screen with currency selection and preferences
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    currentUser: User?,
    defaultCurrency: Currency,
    onCurrencySelected: (Currency) -> Unit,
    onResetPreferences: () -> Unit,
    onBackPressed: () -> Unit
) {
    var showCurrencyPicker by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Settings") },
                navigationIcon = {
                    IconButton(onClick = onBackPressed) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(vertical = 8.dp)
        ) {
            // Currency Settings Section
            item {
                SectionHeader(title = "Currency Settings")
            }

            item {
                CurrencyPreferenceItem(
                    currentCurrency = defaultCurrency,
                    onClick = { showCurrencyPicker = true }
                )
            }

            item {
                Text(
                    text = "All expenses will be displayed in your selected currency.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                )
            }

            // User Information Section
            if (currentUser != null) {
                item {
                    Spacer(modifier = Modifier.height(16.dp))
                    SectionHeader(title = "User Information")
                }

                item {
                    UserInfoItem(label = "Name", value = currentUser.name)
                }

                currentUser.email?.let { email ->
                    item {
                        UserInfoItem(label = "Email", value = email)
                    }
                }

                item {
                    UserInfoItem(
                        label = "Member Since",
                        value = formatDate(currentUser.createdAt.toString())
                    )
                }
            }

            // About Section
            item {
                Spacer(modifier = Modifier.height(16.dp))
                SectionHeader(title = "About")
            }

            item {
                UserInfoItem(label = "Version", value = "1.0.0")
            }

            item {
                UserInfoItem(label = "Build", value = "1")
            }

            // Reset Section
            item {
                Spacer(modifier = Modifier.height(24.dp))
            }

            item {
                ResetButton(onClick = onResetPreferences)
            }

            item {
                Spacer(modifier = Modifier.height(24.dp))
            }
        }
    }

    // Currency Picker Dialog
    if (showCurrencyPicker) {
        CurrencyPickerDialog(
            currentCurrency = defaultCurrency,
            onCurrencySelected = { currency ->
                onCurrencySelected(currency)
                showCurrencyPicker = false
            },
            onDismiss = { showCurrencyPicker = false }
        )
    }
}

/**
 * Section Header Component
 */
@Composable
fun SectionHeader(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.titleMedium,
        color = MaterialTheme.colorScheme.primary,
        fontWeight = FontWeight.SemiBold,
        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
    )
}

/**
 * Currency Preference Item
 */
@Composable
fun CurrencyPreferenceItem(
    currentCurrency: Currency,
    onClick: () -> Unit
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 8.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "Default Currency",
                    style = MaterialTheme.typography.bodyLarge
                )
                Spacer(modifier = Modifier.height(4.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = currentCurrency.symbol,
                        style = MaterialTheme.typography.titleLarge,
                        modifier = Modifier.padding(end = 8.dp)
                    )
                    Text(
                        text = currentCurrency.displayName,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            Text(
                text = currentCurrency.code,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

/**
 * User Information Item
 */
@Composable
fun UserInfoItem(label: String, value: String) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = label,
                style = MaterialTheme.typography.bodyLarge
            )
            Text(
                text = value,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

/**
 * Reset Button
 */
@Composable
fun ResetButton(onClick: () -> Unit) {
    Button(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = MaterialTheme.colorScheme.error
        )
    ) {
        Text("Reset to Defaults")
    }
}

/**
 * Currency Picker Dialog
 */
@Composable
fun CurrencyPickerDialog(
    currentCurrency: Currency,
    onCurrencySelected: (Currency) -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Select Currency") },
        text = {
            LazyColumn {
                items(Currency.all) { currency ->
                    CurrencyListItem(
                        currency = currency,
                        isSelected = currency == currentCurrency,
                        onClick = { onCurrencySelected(currency) }
                    )
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

/**
 * Currency List Item for picker
 */
@Composable
fun CurrencyListItem(
    currency: Currency,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(vertical = 8.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Currency Symbol
            Text(
                text = currency.symbol,
                style = MaterialTheme.typography.headlineMedium,
                modifier = Modifier
                    .width(60.dp)
                    .padding(end = 16.dp)
            )

            // Currency Info
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = currency.displayName,
                    style = MaterialTheme.typography.bodyLarge
                )
                Text(
                    text = currency.code,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            // Checkmark for selected
            if (isSelected) {
                Icon(
                    imageVector = Icons.Default.Check,
                    contentDescription = "Selected",
                    tint = MaterialTheme.colorScheme.primary
                )
            }
        }
    }
}

/**
 * Helper function to format date
 */
private fun formatDate(dateString: String): String {
    return try {
        val formatter = DateTimeFormatter.ofPattern("MMM dd, yyyy")
        dateString // Simplified - implement proper date parsing
    } catch (e: Exception) {
        "Unknown"
    }
}

// MARK: - Previews

@Preview(showBackground = true)
@Composable
fun SettingsScreenPreview() {
    MaterialTheme {
        SettingsScreen(
            currentUser = User(name = "John Doe", email = "john@example.com"),
            defaultCurrency = Currency.USD,
            onCurrencySelected = {},
            onResetPreferences = {},
            onBackPressed = {}
        )
    }
}

@Preview(showBackground = true)
@Composable
fun CurrencyListItemPreview() {
    MaterialTheme {
        Column {
            CurrencyListItem(currency = Currency.USD, isSelected = true, onClick = {})
            CurrencyListItem(currency = Currency.AED, isSelected = false, onClick = {})
        }
    }
}
