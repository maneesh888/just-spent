import Foundation
import SwiftUI
import Combine

/**
 * App Lifecycle Manager
 *
 * Centralized management of app lifecycle states and first-launch detection.
 * Coordinates with auto-recording system to prevent duplicate sessions.
 *
 * Responsibilities:
 * - Track first launch vs subsequent launches
 * - Monitor app foreground/background state
 * - Prevent concurrent recording sessions
 * - Provide state to AutoRecordingCoordinator
 *
 * Architecture Pattern: SOLID principles
 * - Single Responsibility: Only manages lifecycle state
 * - Open/Closed: Extensible through delegates/publishers
 * - Dependency Inversion: Depends on abstractions (UserDefaults protocol could be added)
 */
@MainActor
class AppLifecycleManager: ObservableObject {

    // MARK: - Published State

    /// Indicates if this is the first time the app has launched
    @Published private(set) var isFirstLaunch: Bool

    /// Current app state (active, inactive, background)
    @Published private(set) var appState: AppState = .inactive

    /// Whether app just came to foreground (resets after consumption)
    @Published private(set) var didBecomeActive: Bool = false

    /// Whether an auto-recording session is currently active
    @Published private(set) var isAutoRecording: Bool = false

    // MARK: - Private Properties

    private let userDefaults: UserDefaults
    private let firstLaunchKey = "AppLifecycle_FirstLaunchComplete"
    private let lastAppStateKey = "AppLifecycle_LastAppState"

    /// Timestamp when app went to background (nil if never backgrounded or currently active)
    private var lastBackgroundTime: Date?

    /// Threshold for considering app "been away for a while" (30 minutes in seconds)
    private let backgroundThreshold: TimeInterval = 1800 // 30 minutes

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        // Determine if this is first launch
        self.isFirstLaunch = !userDefaults.bool(forKey: firstLaunchKey)

        #if DEBUG
        print("🔄 AppLifecycleManager initialized - First Launch: \(isFirstLaunch)")
        #endif
    }

    // MARK: - Public Interface

    /**
     * Mark first launch as complete
     * Call this after initial permissions are granted or user completes onboarding
     */
    func completeFirstLaunch() {
        guard isFirstLaunch else {
            #if DEBUG
            print("⚠️ completeFirstLaunch() called but not first launch")
            #endif
            return
        }

        userDefaults.set(true, forKey: firstLaunchKey)
        isFirstLaunch = false

        #if DEBUG
        print("✅ First launch marked as complete")
        #endif
    }

    /**
     * Update app state when scene phase changes
     * Should be called from .onChange(of: scenePhase) in App
     */
    func updateAppState(_ newState: AppState) {
        let previousState = appState
        appState = newState

        // Track background time
        if newState == .background {
            lastBackgroundTime = Date()
            #if DEBUG
            print("📱 App went to background - timestamp recorded")
            #endif
        }

        // Detect foreground transition
        if previousState.isBackground && newState == .active {
            didBecomeActive = true

            #if DEBUG
            if let backgroundTime = lastBackgroundTime {
                let timeInBackground = Date().timeIntervalSince(backgroundTime)
                print("📱 App became active (from background) - was backgrounded for \(Int(timeInBackground))s")
            } else {
                print("📱 App became active (from background)")
            }
            #endif
        }

        // Clear background time when active
        if newState == .active {
            // Don't clear immediately - we need it for shouldTriggerAutoRecording check
            // It will be cleared after auto-recording decision is made
        }

        // Save state for crash recovery
        userDefaults.set(newState.rawValue, forKey: lastAppStateKey)

        #if DEBUG
        print("🔄 App state: \(previousState) → \(newState)")
        #endif
    }

    /**
     * Reset the "did become active" flag after it's been consumed
     * Call this after handling the foreground transition
     */
    func consumeForegroundTransition() {
        didBecomeActive = false
    }

    /**
     * Indicate that auto-recording has started
     * Prevents duplicate auto-recording sessions
     */
    func startAutoRecording() {
        guard !isAutoRecording else {
            #if DEBUG
            print("⚠️ Auto-recording already active, ignoring start request")
            #endif
            return
        }

        isAutoRecording = true
        #if DEBUG
        print("🎙️ Auto-recording session started")
        #endif
    }

    /**
     * Indicate that auto-recording has stopped
     */
    func stopAutoRecording() {
        guard isAutoRecording else {
            #if DEBUG
            print("⚠️ Auto-recording not active, ignoring stop request")
            #endif
            return
        }

        isAutoRecording = false
        #if DEBUG
        print("🛑 Auto-recording session stopped")
        #endif
    }

    /**
     * Check if auto-recording should be triggered
     * Returns true only if:
     * 1. Not first launch
     * 2. App is active
     * 3. No auto-recording session active
     * 4. Either never backgrounded OR been in background for ≥30 minutes
     */
    func shouldTriggerAutoRecording() -> Bool {
        // Basic checks
        guard !isFirstLaunch else {
            #if DEBUG
            print("⏸️ Auto-recording skipped: first launch")
            #endif
            return false
        }

        guard appState == .active else {
            #if DEBUG
            print("⏸️ Auto-recording skipped: app not active (\(appState))")
            #endif
            return false
        }

        guard !isAutoRecording else {
            #if DEBUG
            print("⏸️ Auto-recording skipped: already recording")
            #endif
            return false
        }

        // Check background time threshold
        if let backgroundTime = lastBackgroundTime {
            let timeInBackground = Date().timeIntervalSince(backgroundTime)

            if timeInBackground < backgroundThreshold {
                #if DEBUG
                let remaining = Int(backgroundThreshold - timeInBackground)
                print("⏸️ Auto-recording skipped: quick background switch (\(Int(timeInBackground))s < 30min threshold, \(remaining)s remaining)")
                #endif
                // Clear the timestamp after checking since we're not auto-recording
                lastBackgroundTime = nil
                return false
            } else {
                #if DEBUG
                print("✅ Background threshold met (\(Int(timeInBackground))s ≥ 30min) - will auto-record")
                #endif
                // Clear timestamp - we're proceeding with auto-recording
                lastBackgroundTime = nil
                return true
            }
        } else {
            // Never backgrounded (app launch) - should auto-record
            #if DEBUG
            print("✅ App launch (never backgrounded) - will auto-record")
            #endif
            return true
        }
    }

    /**
     * Force reset first launch flag (for testing/debugging only)
     */
    #if DEBUG
    func resetFirstLaunch() {
        userDefaults.removeObject(forKey: firstLaunchKey)
        isFirstLaunch = true
        print("🔄 First launch flag reset (DEBUG)")
    }
    #endif
}

// MARK: - App State Enum

/**
 * Simplified app state tracking
 * Maps to SwiftUI ScenePhase
 */
enum AppState: String {
    case active = "active"
    case inactive = "inactive"
    case background = "background"

    var isBackground: Bool {
        self == .background || self == .inactive
    }

    init(from scenePhase: ScenePhase) {
        switch scenePhase {
        case .active:
            self = .active
        case .inactive:
            self = .inactive
        case .background:
            self = .background
        @unknown default:
            self = .inactive
        }
    }
}
