package com.justspent.app

import android.app.Application
import android.content.Context
import androidx.test.runner.AndroidJUnitRunner

/**
 * Custom test runner for Hilt-based instrumented tests
 *
 * This replaces JustSpentApplication with JustSpentTestApplication during tests.
 * JustSpentTestApplication extends HiltTestApplication to maintain Hilt functionality
 * while also initializing app-specific systems (like Currency) that are normally
 * initialized in the production application.
 */
class HiltTestRunner : AndroidJUnitRunner() {
    override fun newApplication(
        cl: ClassLoader?,
        className: String?,
        context: Context?
    ): Application {
        return super.newApplication(cl, JustSpentTestApplication::class.java.name, context)
    }
}

