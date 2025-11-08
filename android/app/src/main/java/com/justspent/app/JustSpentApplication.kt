package com.justspent.app

import android.app.Application
import com.justspent.app.data.model.Currency
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class JustSpentApplication : Application() {

    override fun onCreate() {
        super.onCreate()

        android.util.Log.d("JustSpentApplication", "🚀 Application created")

        // Initialize currency system from JSON
        Currency.initialize(this)
        android.util.Log.d("JustSpentApplication", "✅ Currency system initialized with ${Currency.all.size} currencies")

        // Note: AppLifecycleManager is registered in MainActivity.onCreate()
        // after Hilt injection is complete
    }
}