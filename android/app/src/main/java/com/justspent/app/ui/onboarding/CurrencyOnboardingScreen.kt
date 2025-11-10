package com.justspent.app.ui.onboarding

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.justspent.app.data.model.Currency
import com.justspent.app.ui.components.PrimaryButton
import com.justspent.app.utils.LocalizationManager

/**
 * Onboarding screen for first-launch default currency selection
 */
@Composable
fun CurrencyOnboardingScreen(
    onCurrencySelected: (Currency) -> Unit,
    onComplete: () -> Unit
) {
    val context = LocalContext.current
    val localization = LocalizationManager.getInstance(context)
    var selectedCurrency by remember { mutableStateOf(Currency.default) }

    Scaffold { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(48.dp))

            // Welcome Header
            WelcomeHeader()

            Spacer(modifier = Modifier.height(32.dp))

            // Currency Selection List (flexible height)
            CurrencySelectionList(
                modifier = Modifier.weight(1f),
                selectedCurrency = selectedCurrency,
                onCurrencySelected = {
                    selectedCurrency = it
                    onCurrencySelected(it) // Notify parent immediately
                }
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Helper Text
            HelperText()

            Spacer(modifier = Modifier.height(24.dp))

            // Continue Button
            PrimaryButton(
                text = localization.get("onboarding.continueButton"),
                onClick = { onComplete() },
                testTag = "continue_button"
            )

            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@Composable
private fun WelcomeHeader() {
    val context = LocalContext.current
    val localization = LocalizationManager.getInstance(context)

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Icon
        Icon(
            imageVector = Icons.Default.CheckCircle,
            contentDescription = null,
            modifier = Modifier.size(80.dp),
            tint = MaterialTheme.colorScheme.primary
        )

        // Title
        Text(
            text = localization.get("onboarding.welcomeTitle"),
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )

        // Subtitle
        Text(
            text = localization.get("onboarding.welcomeSubtitle"),
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
    }
}

@Composable
private fun CurrencySelectionList(
    modifier: Modifier = Modifier,
    selectedCurrency: Currency,
    onCurrencySelected: (Currency) -> Unit
) {
    // Combine default with all common currencies (ensuring no duplicates)
    val allCurrencies = (listOf(Currency.default) + Currency.common)
        .distinctBy { it.code }
        .sortedBy { it != Currency.default } // Default first, then alphabetically

    Surface(
        modifier = modifier
            .fillMaxWidth(),
        shape = MaterialTheme.shapes.medium,
        tonalElevation = 2.dp
    ) {
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .testTag("currency_list"),
            contentPadding = PaddingValues(vertical = 4.dp)
        ) {
            items(allCurrencies) { currency ->
                CurrencyOnboardingRow(
                    currency = currency,
                    isSelected = currency == selectedCurrency,
                    onClick = { onCurrencySelected(currency) }
                )
                if (currency != allCurrencies.last()) {
                    Divider()
                }
            }
        }
    }
}

@Composable
private fun CurrencyOnboardingRow(
    currency: Currency,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .testTag("currency_option_${currency.code}")
    ) {
        Row(
            modifier = Modifier
                .padding(horizontal = 16.dp, vertical = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Currency Symbol
            Text(
                text = currency.symbol,
                style = MaterialTheme.typography.headlineMedium,
                modifier = Modifier.width(50.dp),
                textAlign = TextAlign.Center
            )

            // Currency Info
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    text = currency.displayName,
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Medium
                )
                Text(
                    text = currency.code,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            // Selection Indicator
            RadioButton(
                selected = isSelected,
                onClick = onClick,
                colors = RadioButtonDefaults.colors(
                    selectedColor = MaterialTheme.colorScheme.primary
                )
            )
        }
    }
}

@Composable
private fun HelperText() {
    val context = LocalContext.current
    val localization = LocalizationManager.getInstance(context)

    Text(
        text = localization.get("onboarding.helperText"),
        style = MaterialTheme.typography.bodySmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        textAlign = TextAlign.Center
    )
}

// MARK: - Previews

@Preview(showBackground = true)
@Composable
fun CurrencyOnboardingScreenPreview() {
    MaterialTheme {
        CurrencyOnboardingScreen(
            onCurrencySelected = {},
            onComplete = {}
        )
    }
}

@Preview(showBackground = true)
@Composable
fun CurrencyOnboardingRowPreview() {
    MaterialTheme {
        Column {
            CurrencyOnboardingRow(
                currency = Currency.USD,
                isSelected = true,
                onClick = {}
            )
            Divider()
            CurrencyOnboardingRow(
                currency = Currency.AED,
                isSelected = false,
                onClick = {}
            )
        }
    }
}
