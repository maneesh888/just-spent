import Foundation
import Speech
import AVFoundation

class SpeechRecognitionManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var hasDetectedSpeech = false
    @Published var speechRecognitionAvailable = false

    // MARK: - Private Properties
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()

    // Auto-stop detection
    private var silenceTimer: Timer?
    private var lastSpeechTime = Date()
    private let silenceThreshold = AppConstants.VoiceRecording.silenceThreshold
    private let minimumSpeechDuration = AppConstants.VoiceRecording.minimumSpeechDuration

    // Callbacks
    var onTranscriptionResult: ((String) -> Void)?
    var onError: ((String, Bool) -> Void)? // message, isError

    // MARK: - Setup

    func setupSpeechRecognition() {
        // Don't do anything if we don't have proper Info.plist setup
        guard Bundle.main.object(forInfoDictionaryKey: "NSSpeechRecognitionUsageDescription") != nil else {
            print("❌ NSSpeechRecognitionUsageDescription not found in Info.plist")
            speechRecognitionAvailable = false
            return
        }

        // Initialize speech recognizer first
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

        // Check if speech recognition is available
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("❌ Speech recognition not available on this device")
            speechRecognitionAvailable = false
            return
        }

        speechRecognitionAvailable = true
    }

    // MARK: - Recording Control

    func startRecording() {
        // Check if speech recognition is available
        guard speechRecognitionAvailable, let recognizer = speechRecognizer else {
            onError?("Speech recognition is not available on this device. Voice recording features require speech recognition support.", true)
            return
        }

        // Check if recognizer is available
        guard recognizer.isAvailable else {
            onError?(LocalizedStrings.permissionMessageTempUnavailable, true)
            return
        }

        performRecording()
    }

    func stopRecording() {
        // This method is for manual stop (user taps stop button)
        print("🎙️ Manual stop requested")
        silenceTimer?.invalidate()
        silenceTimer = nil

        // Stop the audio engine first, before finishing the recognition task
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        // Now gracefully finish the recognition task
        // This will trigger the completion handler which will call cleanupRecording()
        recognitionTask?.finish()
    }

    func cleanupRecording() {
        // Clean up UI and audio session
        isRecording = false
        hasDetectedSpeech = false

        // Cancel silence timer
        silenceTimer?.invalidate()
        silenceTimer = nil

        // Reset audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false)
        } catch {
            print("❌ Failed to deactivate audio session: \(error)")
        }

        print("🎙️ Recording stopped")
    }

    // MARK: - Private Methods

    private func performRecording() {
        // Cancel any previous task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ Audio session setup failed: \(error)")
            onError?("Failed to setup audio session", true)
            return
        }

        let inputNode = audioEngine.inputNode

        // Create recognition request
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.shouldReportPartialResults = true

        // Create recognition task
        guard let recognizer = speechRecognizer else {
            onError?("Speech recognition is not available", true)
            return
        }

        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            var isFinal = false
            var finalTranscription = ""

            if let result = result {
                let transcription = result.bestTranscription.formattedString
                print("🎙️ Transcription: \(transcription)")

                // Update speech detection state
                DispatchQueue.main.async {
                    if !transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        self.lastSpeechTime = Date()
                        self.hasDetectedSpeech = true

                        // Reset silence timer since we detected speech
                        self.resetSilenceTimer()
                    }
                }

                isFinal = result.isFinal
                if isFinal {
                    finalTranscription = transcription
                }
            }

            // Handle completion (either final result or error)
            if isFinal || error != nil {
                // Stop audio processing if still running
                if self.audioEngine.isRunning {
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                }
                self.recognitionTask?.cancel()
                self.recognitionTask = nil

                DispatchQueue.main.async {
                    // Cancel silence timer
                    self.silenceTimer?.invalidate()
                    self.silenceTimer = nil

                    if let error = error {
                        print("❌ Speech recognition error: \(error)")
                        // Only show error if it's not a cancellation (which is normal)
                        if (error as NSError).code != 301 { // kLSRErrorDomain Code=301 is cancellation
                            self.onError?("Speech recognition failed: \(error.localizedDescription)", true)
                        }
                    } else if isFinal && !finalTranscription.isEmpty {
                        // Process successful final transcription
                        self.onTranscriptionResult?(finalTranscription)
                    } else {
                        self.onError?("No speech detected. Please try again.", true)
                    }

                    // Clean up UI state
                    self.cleanupRecording()
                }
            }
        }

        // Configure microphone input
        // Get the native format from input node
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Validate the format - if invalid, create a fallback format
        let recordingFormat: AVAudioFormat
        if inputFormat.sampleRate > 0 && inputFormat.channelCount > 0 {
            recordingFormat = inputFormat
        } else {
            // Fallback to a standard format if input format is invalid
            guard let fallbackFormat = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: 44100,
                channels: 1,
                interleaved: false
            ) else {
                print("❌ Failed to create audio format")
                onError?("Failed to configure audio format", true)
                return
            }
            recordingFormat = fallbackFormat
            print("⚠️ Using fallback audio format: \(recordingFormat)")
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
            isRecording = true
            hasDetectedSpeech = false
            lastSpeechTime = Date()

            // Start silence detection timer
            startSilenceDetection()

            print("🎙️ Recording started with auto-stop detection...")
        } catch {
            print("❌ Audio engine failed to start: \(error)")
            onError?("Failed to start recording: \(error.localizedDescription)", true)
        }
    }

    // MARK: - Auto-Stop Detection

    private func startSilenceDetection() {
        // Start a timer that checks for silence every 0.5 seconds
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForSilence()
        }
    }

    private func resetSilenceTimer() {
        // This is called when we detect new speech
        // No need to restart the timer, just update the lastSpeechTime (already done in caller)
    }

    private func checkForSilence() {
        let now = Date()
        let timeSinceLastSpeech = now.timeIntervalSince(lastSpeechTime)
        let timeSinceRecordingStarted = now.timeIntervalSince(lastSpeechTime)

        // Only auto-stop if:
        // 1. We've detected some speech (to avoid immediate stop)
        // 2. It's been silent for longer than our threshold
        // 3. We've been recording for at least the minimum duration
        if hasDetectedSpeech &&
           timeSinceLastSpeech >= silenceThreshold &&
           timeSinceRecordingStarted >= minimumSpeechDuration {

            print("🔇 Auto-stopping recording after \(String(format: "%.1f", timeSinceLastSpeech))s of silence")

            DispatchQueue.main.async {
                self.autoStopRecording()
            }
        }
    }

    private func autoStopRecording() {
        // This method handles automatic stopping due to silence
        print("🎙️ Auto-stop triggered by silence detection")
        silenceTimer?.invalidate()
        silenceTimer = nil
        recognitionTask?.finish() // Gracefully finish - this will trigger the completion handler which calls cleanupRecording()
        // Note: cleanupRecording() is called in the recognition task completion handler, not here
    }
}
