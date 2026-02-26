import Foundation
import Speech
import AVFoundation
import UIKit

class PermissionManager: ObservableObject {
    @Published var speechPermissionGranted = false
    @Published var microphonePermissionGranted = false
    @Published var permissionsChecked = false

    // MARK: - Check Current Permissions

    func checkCurrentPermissions() {
        // Check current speech recognition authorization status
        let speechAuthStatus = SFSpeechRecognizer.authorizationStatus()
        switch speechAuthStatus {
        case .authorized:
            speechPermissionGranted = true
            print("✅ Speech recognition already authorized")
        case .notDetermined:
            print("⏳ Speech recognition permission not determined")
            speechPermissionGranted = false
        case .denied, .restricted:
            speechPermissionGranted = false
            print("❌ Speech recognition permission denied or restricted")
        @unknown default:
            speechPermissionGranted = false
            print("❌ Unknown speech recognition status")
        }

        // Check microphone permission
        let micPermission = AVAudioSession.sharedInstance().recordPermission
        switch micPermission {
        case .granted:
            microphonePermissionGranted = true
            print("✅ Microphone permission already granted")
        case .undetermined:
            print("⏳ Microphone permission not determined")
            microphonePermissionGranted = false
        case .denied:
            microphonePermissionGranted = false
            print("❌ Microphone permission denied")
        @unknown default:
            microphonePermissionGranted = false
            print("❌ Unknown microphone permission status")
        }

        print("🎤 Microphone permission: \(micPermission.rawValue)")
        print("🗣️ Speech recognition status: \(speechAuthStatus.rawValue)")
    }

    // MARK: - Request Initial Permissions

    func requestInitialPermissions(lifecycleManager: AppLifecycleManager, completion: @escaping () -> Void) {
        permissionsChecked = true

        // Skip permission requests during UI testing to prevent system alerts blocking tests
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            print("🧪 UI Testing detected - skipping system permission requests")
            // Default to false (permissions not granted) which the test expects to handle
            completion()
            return
        }

        // First request speech recognition permission
        requestSpeechPermissionAtLaunch { [weak self] speechGranted in
            DispatchQueue.main.async {
                self?.speechPermissionGranted = speechGranted

                // Then request microphone permission
                self?.requestMicrophonePermissionAtLaunch { micGranted in
                    DispatchQueue.main.async {
                        self?.microphonePermissionGranted = micGranted
                        self?.handleInitialPermissionResults(
                            speechGranted: speechGranted,
                            micGranted: micGranted,
                            lifecycleManager: lifecycleManager
                        )
                        completion()
                    }
                }
            }
        }
    }

    private func requestSpeechPermissionAtLaunch(completion: @escaping (Bool) -> Void) {
        let currentStatus = SFSpeechRecognizer.authorizationStatus()

        switch currentStatus {
        case .authorized:
            completion(true)
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { authStatus in
                completion(authStatus == .authorized)
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    private func requestMicrophonePermissionAtLaunch(completion: @escaping (Bool) -> Void) {
        let currentPermission = AVAudioSession.sharedInstance().recordPermission

        switch currentPermission {
        case .granted:
            completion(true)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                completion(granted)
            }
        case .denied:
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    @MainActor
    private func handleInitialPermissionResults(speechGranted: Bool, micGranted: Bool, lifecycleManager: AppLifecycleManager) {
        if speechGranted && micGranted {
            print("✅ All permissions granted at launch")
            // Mark first launch as complete if this was first time
            if lifecycleManager.isFirstLaunch {
                lifecycleManager.completeFirstLaunch()
                print("✅ First launch completed - auto-recording will be available next time")
            }
            // No need to show any alert, everything is ready
        } else {
            // Don't show alerts at launch - just log the status
            // Users will see the permission status in the UI and can tap Grant Permissions if needed
            print("ℹ️ Some permissions not granted at launch - UI will reflect this")
            if !speechGranted {
                print("   - Speech Recognition permission needed")
            }
            if !micGranted {
                print("   - Microphone permission needed")
            }
        }
    }

    // MARK: - Open Settings

    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}
