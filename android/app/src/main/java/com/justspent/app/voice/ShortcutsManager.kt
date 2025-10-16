package com.justspent.app.voice

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import com.justspent.app.R
import com.justspent.app.data.model.Expense
import dagger.hilt.android.qualifiers.ApplicationContext
import java.math.BigDecimal
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ShortcutsManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    
    companion object {
        private const val MAX_SHORTCUTS = 4
        private const val SHORTCUT_ID_PREFIX = "expense_"
    }
    
    /**
     * Donate a shortcut after successful expense logging
     */
    fun donateExpenseShortcut(expense: Expense) {
        try {
            val shortcutId = "${SHORTCUT_ID_PREFIX}${expense.category.lowercase()}_${expense.amount.toInt()}"
            
            val intent = createExpenseIntent(
                amount = expense.amount,
                category = expense.category,
                merchant = expense.merchant
            )
            
            val shortcut = ShortcutInfoCompat.Builder(context, shortcutId)
                .setShortLabel(getShortLabel(expense))
                .setLongLabel(getLongLabel(expense))
                .setIcon(getIconForCategory(expense.category))
                .setIntent(intent)
                .build()
            
            ShortcutManagerCompat.pushDynamicShortcut(context, shortcut)
        } catch (e: Exception) {
            // Log error but don't crash
            android.util.Log.e("ShortcutsManager", "Failed to donate shortcut", e)
        }
    }
    
    /**
     * Create contextual shortcuts based on patterns
     */
    fun createContextualShortcuts(shortcutContext: ShortcutContext) {
        val shortcuts = when (shortcutContext) {
            ShortcutContext.MEAL_TIME -> createMealTimeShortcuts()
            ShortcutContext.COMMUTING -> createTransportShortcuts()
            ShortcutContext.SHOPPING -> createShoppingShortcuts()
            ShortcutContext.END_OF_DAY -> createViewShortcuts()
        }
        
        shortcuts.forEach { shortcut ->
            ShortcutManagerCompat.pushDynamicShortcut(context, shortcut)
        }
    }
    
    /**
     * Create frequently used expense shortcuts
     */
    fun createQuickAddShortcuts() {
        val commonExpenses = listOf(
            ExpenseShortcut(BigDecimal("5.00"), "Food & Dining", "Morning coffee"),
            ExpenseShortcut(BigDecimal("15.00"), "Food & Dining", "Lunch expense"),
            ExpenseShortcut(BigDecimal("50.00"), "Transportation", "Gas fill up"),
            ExpenseShortcut(BigDecimal("100.00"), "Grocery", "Weekly groceries")
        )
        
        commonExpenses.forEachIndexed { index, expense ->
            val shortcutId = "${SHORTCUT_ID_PREFIX}quick_${index}"
            
            val intent = createExpenseIntent(
                amount = expense.amount,
                category = expense.category,
                merchant = null
            )
            
            val shortcut = ShortcutInfoCompat.Builder(context, shortcutId)
                .setShortLabel(expense.label)
                .setLongLabel("Log ${expense.amount} for ${expense.category}")
                .setIcon(getIconForCategory(expense.category))
                .setIntent(intent)
                .build()
            
            ShortcutManagerCompat.pushDynamicShortcut(context, shortcut)
        }
    }
    
    /**
     * Get suggested voice phrases for user training
     */
    fun getVoiceTrainingPhrases(locale: Locale = Locale.getDefault()): List<String> {
        val basePhrases = listOf(
            "I just spent 25 dollars on food",
            "I paid 50 dollars for groceries at the supermarket",
            "Log 15 dollars for lunch",
            "I spent 30 dollars on gas",
            "I bought coffee for 5 dollars",
            "Add 100 dollars shopping expense"
        )
        
        return when (locale.country) {
            "AE" -> basePhrases.map { it.replace("dollars", "dirhams") } +
                    listOf(
                        "I just spent 50 AED on groceries",
                        "I paid 25 dirhams for lunch",
                        "Log 100 AED for shopping"
                    )
            "GB" -> basePhrases.map { it.replace("dollars", "pounds") } +
                    listOf(
                        "I just spent 20 pounds on petrol",
                        "I paid 15 pounds for lunch"
                    )
            else -> basePhrases
        }
    }
    
    /**
     * Clean up old shortcuts to maintain relevance
     */
    fun cleanupOldShortcuts() {
        val dynamicShortcuts = ShortcutManagerCompat.getDynamicShortcuts(context)
        
        if (dynamicShortcuts.size > MAX_SHORTCUTS) {
            // Remove oldest shortcuts
            val shortcutsToRemove = dynamicShortcuts
                .sortedBy { it.lastChangedTimestamp }
                .take(dynamicShortcuts.size - MAX_SHORTCUTS)
                .map { it.id }
            
            ShortcutManagerCompat.removeDynamicShortcuts(context, shortcutsToRemove)
        }
    }
    
    // Private helper methods
    
    private fun createExpenseIntent(
        amount: BigDecimal,
        category: String,
        merchant: String?
    ): Intent {
        val uri = Uri.Builder()
            .scheme("https")
            .authority("justspent.app")
            .path("/expense")
            .appendQueryParameter("amount", amount.toString())
            .appendQueryParameter("category", category)
            .apply {
                merchant?.let { appendQueryParameter("merchant", it) }
            }
            .build()
        
        return Intent(Intent.ACTION_VIEW, uri)
    }
    
    private fun getShortLabel(expense: Expense): String {
        return "${expense.currency} ${expense.amount.toInt()}"
    }
    
    private fun getLongLabel(expense: Expense): String {
        return buildString {
            append("${expense.currency} ${expense.amount}")
            expense.merchant?.let { append(" at $it") }
            append(" - ${expense.category}")
        }
    }
    
    private fun getIconForCategory(category: String): IconCompat {
        val iconRes = when (category.lowercase()) {
            "food & dining" -> android.R.drawable.ic_menu_recent_history
            "grocery" -> android.R.drawable.ic_menu_agenda
            "transportation" -> android.R.drawable.ic_menu_directions
            "shopping" -> android.R.drawable.ic_menu_gallery
            "entertainment" -> android.R.drawable.ic_menu_slideshow
            "bills & utilities" -> android.R.drawable.ic_menu_save
            "healthcare" -> android.R.drawable.ic_menu_help
            "education" -> android.R.drawable.ic_menu_info_details
            else -> android.R.drawable.ic_menu_add
        }
        return IconCompat.createWithResource(context, iconRes)
    }
    
    private fun createMealTimeShortcuts(): List<ShortcutInfoCompat> {
        val intent = createExpenseIntent(
            amount = BigDecimal("15.00"),
            category = "Food & Dining",
            merchant = null
        )
        
        return listOf(
            ShortcutInfoCompat.Builder(context, "meal_expense")
                .setShortLabel("Meal")
                .setLongLabel("Log meal expense")
                .setIcon(getIconForCategory("Food & Dining"))
                .setIntent(intent)
                .build()
        )
    }
    
    private fun createTransportShortcuts(): List<ShortcutInfoCompat> {
        val intent = createExpenseIntent(
            amount = BigDecimal("25.00"),
            category = "Transportation",
            merchant = null
        )
        
        return listOf(
            ShortcutInfoCompat.Builder(context, "transport_expense")
                .setShortLabel("Transport")
                .setLongLabel("Log transport expense")
                .setIcon(getIconForCategory("Transportation"))
                .setIntent(intent)
                .build()
        )
    }
    
    private fun createShoppingShortcuts(): List<ShortcutInfoCompat> {
        val intent = createExpenseIntent(
            amount = BigDecimal("50.00"),
            category = "Shopping",
            merchant = null
        )
        
        return listOf(
            ShortcutInfoCompat.Builder(context, "shopping_expense")
                .setShortLabel("Shopping")
                .setLongLabel("Log shopping expense")
                .setIcon(getIconForCategory("Shopping"))
                .setIntent(intent)
                .build()
        )
    }
    
    private fun createViewShortcuts(): List<ShortcutInfoCompat> {
        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse("https://justspent.app/view?period=today")
        }
        
        return listOf(
            ShortcutInfoCompat.Builder(context, "view_today")
                .setShortLabel("Today")
                .setLongLabel("View today's expenses")
                .setIcon(IconCompat.createWithResource(context, android.R.drawable.ic_menu_today))
                .setIntent(intent)
                .build()
        )
    }
}

// Supporting types

enum class ShortcutContext {
    MEAL_TIME,
    COMMUTING,
    SHOPPING,
    END_OF_DAY
}

private data class ExpenseShortcut(
    val amount: BigDecimal,
    val category: String,
    val label: String
)