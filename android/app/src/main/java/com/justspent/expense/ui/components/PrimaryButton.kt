package com.justspent.expense.ui.components

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp

/**
 * Primary button component with consistent styling across the app
 *
 * Design specifications:
 * - Height: 56dp (optimal touch target)
 * - Corner radius: 12dp
 * - Background: Primary color (blue)
 * - Text: White, titleMedium font, SemiBold weight
 * - Full width layout
 *
 * Matches iOS PrimaryButton for cross-platform consistency
 */
@Composable
fun PrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    testTag: String = "primary_button"
) {
    Button(
        onClick = onClick,
        modifier = modifier
            .fillMaxWidth()
            .height(56.dp)
            .testTag(testTag),
        enabled = enabled,
        shape = RoundedCornerShape(12.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = MaterialTheme.colorScheme.primary,
            contentColor = Color.White,
            disabledContainerColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.4f),
            disabledContentColor = Color.White.copy(alpha = 0.6f)
        ),
        elevation = ButtonDefaults.buttonElevation(
            defaultElevation = 2.dp,
            pressedElevation = 4.dp,
            disabledElevation = 0.dp
        )
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold
        )
    }
}

// MARK: - Preview

@Preview(showBackground = true)
@Composable
fun PrimaryButtonPreview() {
    MaterialTheme {
        PrimaryButton(
            text = "Continue",
            onClick = {}
        )
    }
}

@Preview(showBackground = true)
@Composable
fun PrimaryButtonDisabledPreview() {
    MaterialTheme {
        PrimaryButton(
            text = "Disabled Button",
            onClick = {},
            enabled = false
        )
    }
}
