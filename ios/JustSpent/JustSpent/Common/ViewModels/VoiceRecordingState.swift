//
//  VoiceRecordingState.swift
//  JustSpent
//
//  Created by Claude Code on 2025-10-20.
//  Shared observable state for voice recording across views
//

import SwiftUI
import Speech
import AVFoundation

/// Observable state object for voice recording shared across all views
class VoiceRecordingState: ObservableObject {
    // Speech Recognition States
    @Published var isRecording = false
    @Published var speechRecognizer: SFSpeechRecognizer?
    @Published var recognitionTask: SFSpeechRecognitionTask?
    @Published var audioEngine = AVAudioEngine()
    @Published var speechPermissionGranted = false
    @Published var microphonePermissionGranted = false
    @Published var speechRecognitionAvailable = false

    // Auto-stop detection states
    @Published var silenceTimer: Timer?
    @Published var lastSpeechTime = Date()
    @Published var hasDetectedSpeech = false
    @Published var silenceThreshold = AppConstants.VoiceRecording.silenceThreshold
    @Published var minimumSpeechDuration = AppConstants.VoiceRecording.minimumSpeechDuration

    // Permission UI states
    @Published var showingPermissionAlert = false
    @Published var permissionAlertTitle = ""
    @Published var permissionAlertMessage = ""

    // Voice input text
    @Published var voiceInputText = ""

    // Shared instance for global access
    static let shared = VoiceRecordingState()

    private init() {
        // Private initializer for singleton pattern
    }
}
