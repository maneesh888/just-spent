package com.justspent.expense.utils

import android.content.Context
import org.json.JSONObject
import java.io.IOException

/**
 * LocalizationManager
 *
 * Loads localization strings from shared localizations.json
 * Single source of truth for cross-platform consistency
 */
class LocalizationManager private constructor(context: Context) {

    private val localizations: JSONObject
    private val platform = "android"

    init {
        localizations = loadLocalizations(context)
    }

    companion object {
        @Volatile
        private var instance: LocalizationManager? = null

        fun getInstance(context: Context): LocalizationManager {
            return instance ?: synchronized(this) {
                instance ?: LocalizationManager(context.applicationContext).also { instance = it }
            }
        }
    }

    // MARK: - Loading

    private fun loadLocalizations(context: Context): JSONObject {
        return try {
            // Try multiple paths to find the shared localization file

            // 1. Try from current working directory (works in tests)
            var localizationFile = java.io.File("shared/localizations.json")
            if (localizationFile.exists()) {
                val json = localizationFile.readText()
                val jsonObject = JSONObject(json)
                println("📍 Found localizations.json in shared folder (from current dir)")
                println("✅ Loaded localizations.json version: ${jsonObject.optString("version", "unknown")}")
                return jsonObject
            }

            // 2. Search up from current directory to find project root (works in tests)
            val searchedFile = findLocalizationFileFromProjectRoot()
            if (searchedFile != null && searchedFile.exists()) {
                val json = searchedFile.readText()
                val jsonObject = JSONObject(json)
                println("📍 Found localizations.json by searching up from current directory")
                println("✅ Loaded localizations.json version: ${jsonObject.optString("version", "unknown")}")
                return jsonObject
            }

            // 3. Fallback: load from assets (for production APK)
            val json = context.assets.open("localizations.json").bufferedReader().use { it.readText() }
            val jsonObject = JSONObject(json)
            println("📍 Found localizations.json in app assets")
            println("✅ Loaded localizations.json version: ${jsonObject.optString("version", "unknown")}")
            jsonObject
        } catch (e: IOException) {
            println("❌ Failed to load localizations.json from any location")
            println("   Searched: current dir, project root, and app assets")
            println("   Error: ${e.message}")
            JSONObject()
        }
    }

    /**
     * Search for localizations.json by traversing up from current directory
     * Similar to iOS implementation
     */
    private fun findLocalizationFileFromProjectRoot(): java.io.File? {
        var currentDir = java.io.File(System.getProperty("user.dir") ?: ".")

        // Search up to 10 levels to find project root
        for (i in 0..9) {
            val sharedPath = java.io.File(currentDir, "shared/localizations.json")
            if (sharedPath.exists()) {
                println("📍 Found localizations.json by searching up $i levels")
                return sharedPath
            }

            // Go up one level
            val parentDir = currentDir.parentFile
            if (parentDir == null || parentDir == currentDir) {
                break // Reached filesystem root
            }
            currentDir = parentDir
        }

        return null
    }

    // MARK: - String Access

    /**
     * Get localized string by dot-notation path
     * Example: get("app.title") returns "Just Spent"
     */
    fun get(key: String): String {
        val components = key.split(".")
        var current: Any? = localizations

        for (component in components) {
            current = when (current) {
                is JSONObject -> current.opt(component)
                else -> null
            }
            if (current == null) {
                return "[$key]" // Return key in brackets if not found
            }
        }

        // Handle platform-specific strings
        if (current is JSONObject) {
            val platformValue = current.optString(platform)
            if (platformValue.isNotEmpty()) {
                return platformValue
            }
        }

        // Handle regular strings
        if (current is String) {
            return current
        }

        return "[$key]" // Return key in brackets if not found
    }

    // MARK: - Convenience Accessors

    val appTitle: String get() = get("app.title")
    val appSubtitle: String get() = get("app.subtitle")
    val appTotalLabel: String get() = get("app.totalLabel")

    val emptyStateNoExpenses: String get() = get("emptyState.noExpenses")
    val emptyStateTapVoiceButton: String get() = get("emptyState.tapVoiceButton")

    val buttonOK: String get() = get("buttons.ok")
    val buttonCancel: String get() = get("buttons.cancel")
    val buttonRetry: String get() = get("buttons.retry")

    val voiceListening: String get() = get("voice.listening")
    val voiceProcessing: String get() = get("voice.processing")

    val categoryFoodDining: String get() = get("categories.foodDining")
    val categoryGrocery: String get() = get("categories.grocery")
    val categoryTransportation: String get() = get("categories.transportation")
    val categoryShopping: String get() = get("categories.shopping")
    val categoryEntertainment: String get() = get("categories.entertainment")
    val categoryBills: String get() = get("categories.bills")
    val categoryHealthcare: String get() = get("categories.healthcare")
    val categoryEducation: String get() = get("categories.education")
    val categoryOther: String get() = get("categories.other")
    val categoryUnknown: String get() = get("categories.unknown")
}
