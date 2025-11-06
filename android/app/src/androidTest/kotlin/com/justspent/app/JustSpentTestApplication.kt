package com.justspent.app

import com.justspent.app.data.model.Currency
import dagger.hilt.android.testing.HiltTestApplication

/**
 * Custom test application for instrumented tests
 *
 * Extends HiltTestApplication to maintain Hilt dependency injection functionality
 * while also initializing app-specific systems (like Currency) that are normally
 * initialized in JustSpentApplication.onCreate()
 *
 * This ensures tests run in an environment similar to production while maintaining
 * the testing benefits of HiltTestApplication.
 */
class JustSpentTestApplication : HiltTestApplication() {

    override fun onCreate() {
        super.onCreate()

        // Initialize currency system from JSON
        // This is normally done in JustSpentApplication.onCreate() but HiltTestRunner
        // replaces JustSpentApplication with HiltTestApplication, so we need to do it here
        Currency.initialize(this)

        android.util.Log.d("JustSpentTestApplication", "✅ Test application created with Currency system initialized")
    }
}
