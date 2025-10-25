//
//  FloatingVoiceButton.swift
//  JustSpent
//
//  Created by Claude Code on 2025-10-20.
//  Reusable floating voice recording button component
//

import SwiftUI

/// Floating action button for voice recording
/// Appears consistently across all app views with circular shadow design
struct FloatingVoiceButton: View {
    @Binding var isRecording: Bool
    @Binding var hasDetectedSpeech: Bool
    @Binding var speechRecognitionAvailable: Bool
    @Binding var speechPermissionGranted: Bool
    @Binding var microphonePermissionGranted: Bool

    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    let onPermissionAlert: () -> Void

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()

                VStack(spacing: 8) {
                    // Listening indicator (when recording)
                    if isRecording {
                        VStack(spacing: 4) {
                            HStack {
                                Circle()
                                    .fill(hasDetectedSpeech ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(isRecording ? 1.0 : 0.5)
                                    .animation(.easeInOut(duration: 0.5).repeatForever(), value: isRecording)
                                Text(hasDetectedSpeech ? LocalizedStrings.voiceProcessing : LocalizedStrings.voiceListening)
                                    .foregroundColor(hasDetectedSpeech ? .green : .red)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }

                            // Auto-stop indicator
                            Text(LocalizedStrings.voiceWillStopAuto)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }

                    // Main floating button
                    Button(action: {
                        if isRecording {
                            onStopRecording()
                        } else {
                            // Extra safety check before any speech recognition
                            guard speechRecognitionAvailable else {
                                onPermissionAlert()
                                return
                            }
                            onStartRecording()
                        }
                    }) {
                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(isRecording ? Color.red : Color.blue)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            .scaleEffect(isRecording ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isRecording)
                    }
                    .accessibilityIdentifier("voice_recording_button")
                    .accessibilityLabel(isRecording ? "Stop recording" : "Start voice recording")
                    .disabled(!speechRecognitionAvailable || (!speechPermissionGranted || !microphonePermissionGranted))
                    .opacity((speechRecognitionAvailable && speechPermissionGranted && microphonePermissionGranted) ? 1.0 : 0.6)
                }

                Spacer()
            }
            .padding(.bottom, 34) // Safe area bottom padding
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()

        FloatingVoiceButton(
            isRecording: .constant(false),
            hasDetectedSpeech: .constant(false),
            speechRecognitionAvailable: .constant(true),
            speechPermissionGranted: .constant(true),
            microphonePermissionGranted: .constant(true),
            onStartRecording: { print("Start recording") },
            onStopRecording: { print("Stop recording") },
            onPermissionAlert: { print("Show permission alert") }
        )
    }
}

#Preview("Recording") {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()

        FloatingVoiceButton(
            isRecording: .constant(true),
            hasDetectedSpeech: .constant(true),
            speechRecognitionAvailable: .constant(true),
            speechPermissionGranted: .constant(true),
            microphonePermissionGranted: .constant(true),
            onStartRecording: { print("Start recording") },
            onStopRecording: { print("Stop recording") },
            onPermissionAlert: { print("Show permission alert") }
        )
    }
}
