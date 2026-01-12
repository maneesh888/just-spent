package com.justspent.expense.voice

import android.content.Context
import android.content.Intent
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.coroutines.CoroutineContext

/**
 * Voice Recording Manager with Auto-Stop Detection
 *
 * Mirrors iOS implementation from ContentView.swift:427-863
 * Features:
 * - Real-time speech recognition using Android SpeechRecognizer
 * - Auto-stop detection after configurable silence threshold
 * - Graceful audio session management
 * - Speech detection feedback
 */
@Singleton
class VoiceRecordingManager @Inject constructor(
    @ApplicationContext private val context: Context
) : CoroutineContext by Dispatchers.Main {

    companion object {
        private const val TAG = "VoiceRecordingManager"
        private const val SILENCE_THRESHOLD_MS = 3500L // 3.5 seconds of silence (increased for natural pauses)
        private const val MINIMUM_SPEECH_DURATION_MS = 500L // Minimum 0.5 second of speech
        private const val SILENCE_CHECK_INTERVAL_MS = 500L // Check every 0.5 seconds
    }

    // Speech recognizer
    private var speechRecognizer: SpeechRecognizer? = null
    private var recognitionIntent: Intent? = null

    // State management
    private val _recordingState = MutableStateFlow<RecordingState>(RecordingState.Idle)
    val recordingState: StateFlow<RecordingState> = _recordingState.asStateFlow()

    // Auto-stop detection
    private var silenceDetectionJob: Job? = null
    private var lastSpeechTimeMs: Long = 0
    private var recordingStartTimeMs: Long = 0
    private var hasDetectedSpeech: Boolean = false

    // Configuration
    var silenceThresholdMs: Long = SILENCE_THRESHOLD_MS
    var minimumSpeechDurationMs: Long = MINIMUM_SPEECH_DURATION_MS

    // Transcription accumulation
    private val _partialTranscription = MutableStateFlow("")
    val partialTranscription: StateFlow<String> = _partialTranscription.asStateFlow()

    /**
     * Initialize speech recognizer
     */
    fun initialize() {
        if (!SpeechRecognizer.isRecognitionAvailable(context)) {
            Log.e(TAG, "Speech recognition not available on this device")
            _recordingState.value = RecordingState.Error("Speech recognition not available")
            return
        }

        try {
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
            setupRecognitionIntent()
            Log.d(TAG, "VoiceRecordingManager initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize speech recognizer", e)
            _recordingState.value = RecordingState.Error("Initialization failed: ${e.message}")
        }
    }

    /**
     * Start recording with auto-stop detection
     */
    fun startRecording(
        onResult: (String) -> Unit,
        onError: (String) -> Unit
    ) {
        if (_recordingState.value is RecordingState.Recording) {
            Log.w(TAG, "Already recording, ignoring start request")
            return
        }

        // Reset state
        hasDetectedSpeech = false
        lastSpeechTimeMs = System.currentTimeMillis()
        recordingStartTimeMs = System.currentTimeMillis()
        _partialTranscription.value = ""

        // Setup recognizer
        if (speechRecognizer == null) {
            initialize()
        }

        speechRecognizer?.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                Log.d(TAG, "Ready for speech")
                _recordingState.value = RecordingState.Recording(
                    hasDetectedSpeech = false,
                    partialTranscription = ""
                )
            }

            override fun onBeginningOfSpeech() {
                Log.d(TAG, "Speech detected - beginning")
                hasDetectedSpeech = true
                lastSpeechTimeMs = System.currentTimeMillis()
                _recordingState.value = RecordingState.Recording(
                    hasDetectedSpeech = true,
                    partialTranscription = _partialTranscription.value
                )
            }

            override fun onRmsChanged(rmsdB: Float) {
                // Audio level changed - could use this for visual feedback
            }

            override fun onBufferReceived(buffer: ByteArray?) {
                // Audio buffer received
            }

            override fun onEndOfSpeech() {
                Log.d(TAG, "End of speech detected")
            }

            override fun onError(error: Int) {
                val errorMessage = getErrorMessage(error)
                Log.e(TAG, "Recognition error: $errorMessage (code: $error)")

                // Don't treat "No match" as error if we have partial results
                if (error == SpeechRecognizer.ERROR_NO_MATCH && _partialTranscription.value.isNotEmpty()) {
                    Log.d(TAG, "No match error but have partial transcription, treating as success")
                    onResult(_partialTranscription.value)
                    cleanup()
                } else {
                    _recordingState.value = RecordingState.Error(errorMessage)
                    onError(errorMessage)
                    cleanup()
                }
            }

            override fun onResults(results: Bundle?) {
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                val confidenceScores = results?.getFloatArray(SpeechRecognizer.CONFIDENCE_SCORES)

                // Log all alternatives with confidence scores
                if (matches != null && confidenceScores != null) {
                    matches.forEachIndexed { index, match ->
                        val confidence = if (index < confidenceScores.size) confidenceScores[index] else 0f
                        Log.d(TAG, "Alternative $index: '$match' (confidence: $confidence)")
                    }
                }

                // Select best transcription based on confidence
                val transcription = selectBestTranscription(matches, confidenceScores)

                Log.d(TAG, "Final transcription: $transcription")

                if (transcription.isNotEmpty()) {
                    _partialTranscription.value = transcription
                    _recordingState.value = RecordingState.Success(transcription)
                    onResult(transcription)
                } else if (_partialTranscription.value.isNotEmpty()) {
                    // Use partial transcription if available
                    Log.d(TAG, "Using partial transcription: ${_partialTranscription.value}")
                    _recordingState.value = RecordingState.Success(_partialTranscription.value)
                    onResult(_partialTranscription.value)
                } else {
                    _recordingState.value = RecordingState.Error("No speech detected")
                    onError("No speech detected")
                }

                cleanup()
            }

            override fun onPartialResults(partialResults: Bundle?) {
                val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                val partialTranscription = matches?.firstOrNull() ?: ""

                if (partialTranscription.isNotEmpty()) {
                    Log.d(TAG, "Partial transcription: $partialTranscription")
                    _partialTranscription.value = partialTranscription
                    lastSpeechTimeMs = System.currentTimeMillis()
                    hasDetectedSpeech = true

                    _recordingState.value = RecordingState.Recording(
                        hasDetectedSpeech = true,
                        partialTranscription = partialTranscription
                    )
                }
            }

            override fun onEvent(eventType: Int, params: Bundle?) {
                // Custom events
            }
        })

        try {
            // Start recognition
            speechRecognizer?.startListening(recognitionIntent)

            // Start silence detection
            startSilenceDetection(onResult, onError)

            Log.d(TAG, "Voice recording started with auto-stop detection")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start recording", e)
            _recordingState.value = RecordingState.Error("Failed to start: ${e.message}")
            onError("Failed to start recording: ${e.message}")
        }
    }

    /**
     * Stop recording manually
     */
    fun stopRecording() {
        Log.d(TAG, "Manual stop requested")
        silenceDetectionJob?.cancel()
        silenceDetectionJob = null

        speechRecognizer?.stopListening()

        // Don't cleanup immediately - let onResults handle it
    }

    /**
     * Start silence detection timer
     */
    private fun startSilenceDetection(
        onResult: (String) -> Unit,
        onError: (String) -> Unit
    ) {
        silenceDetectionJob?.cancel()
        silenceDetectionJob = CoroutineScope(Dispatchers.Default).launch {
            while (isActive) {
                delay(SILENCE_CHECK_INTERVAL_MS)

                val now = System.currentTimeMillis()
                val timeSinceLastSpeech = now - lastSpeechTimeMs
                val timeSinceRecordingStarted = now - recordingStartTimeMs

                // Auto-stop conditions:
                // 1. Speech was detected
                // 2. Silent for longer than threshold
                // 3. Recording duration meets minimum
                if (hasDetectedSpeech &&
                    timeSinceLastSpeech >= silenceThresholdMs &&
                    timeSinceRecordingStarted >= minimumSpeechDurationMs) {

                    Log.d(TAG, "Auto-stopping after ${timeSinceLastSpeech}ms of silence")

                    withContext(Dispatchers.Main) {
                        autoStopRecording(onResult, onError)
                    }
                    break
                }
            }
        }
    }

    /**
     * Auto-stop recording due to silence
     */
    private fun autoStopRecording(
        onResult: (String) -> Unit,
        onError: (String) -> Unit
    ) {
        Log.d(TAG, "Auto-stop triggered by silence detection")

        // Stop listening
        speechRecognizer?.stopListening()

        // Use partial transcription if available
        val transcription = _partialTranscription.value
        if (transcription.isNotEmpty()) {
            Log.d(TAG, "Using partial transcription from auto-stop: $transcription")
            _recordingState.value = RecordingState.Success(transcription)
            onResult(transcription)
        } else {
            Log.w(TAG, "Auto-stop triggered but no transcription available")
            _recordingState.value = RecordingState.Error("No speech detected")
            onError("No speech detected")
        }

        cleanup()
    }

    /**
     * Setup recognition intent with optimal parameters for maximum accuracy
     */
    private fun setupRecognitionIntent() {
        recognitionIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            // Use WEB_SEARCH model for better accuracy with natural language
            // This model is optimized for voice search queries and short commands
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_WEB_SEARCH)

            // Set primary language with fallbacks
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, Locale.getDefault().language)

            // Enable partial results for real-time feedback
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)

            // Request more alternatives for better accuracy
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 5)

            // Enable confidence scores
            putExtra(RecognizerIntent.EXTRA_CONFIDENCE_SCORES, true)

            // Identify calling package
            putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, context.packageName)

            // Optimize silence detection timing - increased for natural conversation pauses
            // Complete silence: 8 seconds (more time for thinking pauses)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 8000L)
            // Possible complete silence: 5 seconds (triggers partial results but still allows pauses)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 5000L)
            // Minimum length of speech: 500ms (detect quick commands)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 500L)

            // Prefer offline recognition for privacy and speed (fallback to online)
            putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, false) // Use online for better accuracy

            // Request secure recognition (doesn't send to Google's servers for personalization)
            putExtra(RecognizerIntent.EXTRA_SECURE, false) // Allow personalization for accuracy

            // Enable punctuation for better transcription
            putExtra("android.speech.extra.DICTATION_MODE", true)
        }
    }

    /**
     * Cleanup resources
     */
    private fun cleanup() {
        silenceDetectionJob?.cancel()
        silenceDetectionJob = null

        if (_recordingState.value !is RecordingState.Success &&
            _recordingState.value !is RecordingState.Error) {
            _recordingState.value = RecordingState.Idle
        }
    }

    /**
     * Release all resources
     */
    fun release() {
        Log.d(TAG, "Releasing VoiceRecordingManager resources")
        cleanup()
        speechRecognizer?.destroy()
        speechRecognizer = null
        _recordingState.value = RecordingState.Idle
    }

    /**
     * Check if speech recognition is available
     */
    fun isAvailable(): Boolean {
        return SpeechRecognizer.isRecognitionAvailable(context)
    }

    /**
     * Select best transcription from alternatives using confidence scores and context
     */
    private fun selectBestTranscription(
        matches: ArrayList<String>?,
        confidenceScores: FloatArray?
    ): String {
        if (matches.isNullOrEmpty()) return ""

        // If no confidence scores, return first match
        if (confidenceScores == null || confidenceScores.isEmpty()) {
            return matches.firstOrNull() ?: ""
        }

        // Find the match with highest confidence that looks like an expense command
        var bestMatch = matches[0]
        var bestScore = if (confidenceScores.isNotEmpty()) confidenceScores[0] else 0f

        matches.forEachIndexed { index, match ->
            if (index < confidenceScores.size) {
                val confidence = confidenceScores[index]
                val contextScore = calculateContextScore(match)

                // Weighted score: 70% confidence + 30% context
                val totalScore = (confidence * 0.7f) + (contextScore * 0.3f)

                if (totalScore > bestScore) {
                    bestMatch = match
                    bestScore = totalScore
                }
            }
        }

        return bestMatch
    }

    /**
     * Calculate context score for expense-related content
     * Returns a score between 0 and 1 based on how likely this is an expense command
     */
    private fun calculateContextScore(text: String): Float {
        val lowerText = text.lowercase()
        var score = 0f

        // Check for expense-related keywords
        val expenseKeywords = listOf(
            "spent", "paid", "cost", "bought", "purchase", "expense",
            "dollar", "AED", "dirham", "euro", "pound", "rupee"
        )
        expenseKeywords.forEach { keyword ->
            if (lowerText.contains(keyword)) score += 0.2f
        }

        // Check for category keywords
        val categoryKeywords = listOf(
            "food", "grocery", "groceries", "coffee", "lunch", "dinner",
            "gas", "taxi", "uber", "shopping", "clothes"
        )
        categoryKeywords.forEach { keyword ->
            if (lowerText.contains(keyword)) score += 0.15f
        }

        // Check for numbers (likely amounts)
        if (lowerText.matches(Regex(".*\\d+.*"))) {
            score += 0.25f
        }

        // Check for prepositions (at, from, for, on)
        val prepositions = listOf(" at ", " from ", " for ", " on ")
        prepositions.forEach { prep ->
            if (lowerText.contains(prep)) score += 0.1f
        }

        return minOf(score, 1.0f)
    }

    /**
     * Get human-readable error message
     */
    private fun getErrorMessage(error: Int): String {
        return when (error) {
            SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
            SpeechRecognizer.ERROR_CLIENT -> "Client side error"
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
            SpeechRecognizer.ERROR_NETWORK -> "Network error"
            SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
            SpeechRecognizer.ERROR_NO_MATCH -> "No speech detected"
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognition service busy"
            SpeechRecognizer.ERROR_SERVER -> "Server error"
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech input"
            else -> "Unknown error ($error)"
        }
    }
}

/**
 * Recording state sealed class
 */
sealed class RecordingState {
    object Idle : RecordingState()

    data class Recording(
        val hasDetectedSpeech: Boolean,
        val partialTranscription: String
    ) : RecordingState()

    data class Success(val transcription: String) : RecordingState()

    data class Error(val message: String) : RecordingState()
}
