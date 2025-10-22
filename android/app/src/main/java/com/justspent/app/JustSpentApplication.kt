package com.justspent.app

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class JustSpentApplication : Application() {

    override fun onCreate() {
        super.onCreate()

        android.util.Log.d("JustSpentApplication", "🚀 Application created")
        // Note: AppLifecycleManager is registered in MainActivity.onCreate()
        // after Hilt injection is complete
    }
}