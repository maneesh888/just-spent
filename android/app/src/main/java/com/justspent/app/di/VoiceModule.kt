package com.justspent.app.di

import android.content.Context
import com.justspent.app.voice.VoiceCommandProcessor
import com.justspent.app.voice.ShortcutsManager
import com.justspent.app.voice.VoiceRecordingManager
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object VoiceModule {

    @Provides
    @Singleton
    fun provideVoiceCommandProcessor(): VoiceCommandProcessor {
        return VoiceCommandProcessor()
    }

    @Provides
    @Singleton
    fun provideShortcutsManager(
        @ApplicationContext context: Context
    ): ShortcutsManager {
        return ShortcutsManager(context)
    }

    @Provides
    @Singleton
    fun provideVoiceRecordingManager(
        @ApplicationContext context: Context
    ): VoiceRecordingManager {
        return VoiceRecordingManager(context).apply {
            initialize()
        }
    }
}