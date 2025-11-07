package com.justspent.app

import android.app.Application
import com.justspent.app.data.model.Currency
import dagger.hilt.android.testing.CustomTestApplication

/**
 * Base application for custom test application
 *
 * This is used with @CustomTestApplication annotation to create a test application
 * that initializes app-specific systems (like Currency) that are normally
 * initialized in JustSpentApplication.onCreate()
 *
 * Note: Do NOT extend HiltTestApplication directly - it's final. Instead, use this
 * pattern with @CustomTestApplication annotation to let Hilt generate the proper
 * test application class.
 */
open class JustSpentTestApplicationBase : Application() {

    override fun onCreate() {
        super.onCreate()

        // Initialize currency system from JSON
        // This is normally done in JustSpentApplication.onCreate() but during tests
        // the application is replaced with a Hilt-generated test application
        Currency.initialize(this)

        android.util.Log.d("JustSpentTestApplication", "✅ Test application created with Currency system initialized")
    }
}

/**
 * Custom test application annotation that tells Hilt to generate a test application
 * based on JustSpentTestApplicationBase
 */
@CustomTestApplication(JustSpentTestApplicationBase::class)
interface JustSpentTestApplication
