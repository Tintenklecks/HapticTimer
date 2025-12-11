import Combine
import Foundation
import SwiftUI
import UserNotifications

#if os(watchOS)
    import WatchKit
    import HealthKit
#endif

class HapticTimerViewModel: NSObject, ObservableObject {
    @Published var timeRemaining: Int = 60
    @Published var isRunning = false
    @Published var showNotificationExplanationDialog = false
    @Published var showFeedbackAlert = false
    @AppStorage("initialtime") var initialTime: TimeInterval = 60
    @AppStorage("hasShownNotificationExplanation") private var hasShownNotificationExplanation =
        false

    private var intInitialTime: Int {
        Int(initialTime.rounded())
    }

    private var endDate: Date?
    private var lastUpdateTime: Date?
    private var updateTimer: Timer?
    private let hapticService = HapticService.shared

    override init() {
        super.init()
        timeRemaining = intInitialTime

        #if os(iOS) || os(iPadOS)
            hapticService.onFeedbackFailed = { [weak self] in
                DispatchQueue.main.async {
                    self?.showFeedbackAlert = true
                }
            }
        #endif
    }

    var startButtonText: String {
        if isRunning {
            return "Pause"
        } else {
            if timeRemaining > 0 && timeRemaining < intInitialTime {
                return "Resume"
            } else {
                return "Start"
            }
        }
    }

    var showResetButton: Bool {
        timeRemaining <= 0
    }

    var stopButtonText = "Stop"
    var resetButtonText = "Reset"

    func resetButtonAction() {
        stopTimer()
    }

    func stopButtonAction() {
        stopTimer()
    }

    func startButtonAction() {
        if isRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }

    #if os(watchOS)
        private var workoutSession: HKWorkoutSession?
        private let healthStore = HKHealthStore()
    #endif

    func startTimer() {
        guard !isRunning else { return }
        isRunning = true

        // Calculate end date based on current time and remaining time
        endDate = Date().addingTimeInterval(TimeInterval(timeRemaining))
        lastUpdateTime = Date()

        #if os(watchOS)
            startWorkoutSession()
            // Also schedule notifications as a fallback
            scheduleLocalNotifications()
        #endif

        // Start a timer to update the UI every second
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateTime()
        }

        // Ensure timer runs even when scrolling or other UI interactions occur
        if let timer = updateTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func pauseTimer() {
        guard isRunning else { return }
        isRunning = false
        updateTimer?.invalidate()
        updateTimer = nil

        // Calculate remaining time based on end date
        if let endDate = endDate {
            let remaining = Int(endDate.timeIntervalSince(Date()))
            if remaining > 0 {
                timeRemaining = remaining
            } else {
                timeRemaining = 0
                isRunning = false
            }
        }

        #if os(watchOS)
            endWorkoutSession()
        #endif

        // Clear scheduled notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func stopTimer() {
        isRunning = false
        updateTimer?.invalidate()
        updateTimer = nil
        endDate = nil
        lastUpdateTime = nil
        timeRemaining = intInitialTime
        #if os(watchOS)
            endWorkoutSession()
        #endif

        // Clear scheduled notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    #if os(watchOS)
        private func startWorkoutSession() {
            guard HKHealthStore.isHealthDataAvailable() else { return }

            // Request authorization first if needed
            let typesToShare: Set = [HKObjectType.workoutType()]
            let typesToRead: Set = [HKObjectType.workoutType()]

            healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) {
                [weak self] success, error in
                guard success else {
                    print("HealthKit authorization failed: \(String(describing: error))")
                    return
                }

                DispatchQueue.main.async {
                    // Check if we are still running before starting the session
                    // This prevents a race condition where the user might have stopped
                    // the timer while authorization was happening
                    guard let self = self, self.isRunning else { return }
                    self.createAndStartWorkoutSession()
                }
            }
        }

        private func createAndStartWorkoutSession() {
            guard isRunning else { return }

            // End any existing session
            endWorkoutSession()

            let configuration = HKWorkoutConfiguration()
            configuration.activityType = .other
            configuration.locationType = .indoor

            do {
                workoutSession = try HKWorkoutSession(
                    healthStore: healthStore, configuration: configuration)
                workoutSession?.delegate = self
                workoutSession?.startActivity(with: Date())
                print("Starting workout session")
            } catch {
                print("Failed to start workout session: \(error)")
            }
        }

        private func endWorkoutSession() {
            workoutSession?.end()
            workoutSession = nil
            print("Ending workout session")
        }
    #endif

    private func updateTime() {
        guard let endDate = endDate else { return }

        let now = Date()
        let remaining = Int(endDate.timeIntervalSince(now))

        if remaining > 0 {
            // Update the time remaining
            timeRemaining = remaining

            if remaining == 1 {
                // Special handling for the final second
                hapticService.playHaptic(for: remaining)
            } else if remaining % 60 == 0, Intervals.oneMinute.isActive {
                hapticService.playHaptic(for: remaining)
            } else if remaining % 10 == 0, Intervals.tenSeconds.isActive {
                hapticService.playHaptic(for: remaining)
            } else if remaining % 5 == 0, Intervals.fiveSeconds.isActive {
                hapticService.playHaptic(for: remaining)
            } else if Intervals.oneSecond.isActive {
                hapticService.playHaptic(for: remaining)
            }
        } else {
            timeRemaining = 0
            isRunning = false
            updateTimer?.invalidate()
            updateTimer = nil
            hapticService.playTimerEndHaptic()

            #if os(watchOS)
                endWorkoutSession()
            #endif
        }
    }

    func setTime(_ time: TimeInterval) {
        timeRemaining = Int(time + 0.1)
        initialTime = time
    }

    // MARK: - Local Notification Fallback
    private func scheduleLocalNotifications() {
        // Clear existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        guard timeRemaining > 0 else { return }

        // Check if we need to show explanation dialog first
        if !hasShownNotificationExplanation {
            DispatchQueue.main.async {
                self.showNotificationExplanationDialog = true
            }
            return
        }

        let center = UNUserNotificationCenter.current()

        // Request permission
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                self.createTimerNotifications()
            }
        }
    }

    func requestNotificationPermissionAfterExplanation() {
        hasShownNotificationExplanation = true
        showNotificationExplanationDialog = false

        let center = UNUserNotificationCenter.current()

        // Request permission
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                self.createTimerNotifications()
            }
        }
    }

    func cancelNotificationPermissionRequest() {
        showNotificationExplanationDialog = false
    }

    private func createTimerNotifications() {
        let intervals = [1, 5, 10, 60]  // seconds

        for interval in intervals.reversed() {
            if timeRemaining > interval {
                let content = UNMutableNotificationContent()
                content.title = "Haptic Timer"
                content.body = "\(interval) second\(interval == 1 ? "" : "s") remaining"
                content.sound = .default

                let trigger = UNTimeIntervalNotificationTrigger(
                    timeInterval: TimeInterval(timeRemaining - interval),
                    repeats: false
                )

                let request = UNNotificationRequest(
                    identifier: "timer-\(interval)",
                    content: content,
                    trigger: trigger
                )

                UNUserNotificationCenter.current().add(request)
            }
        }

        // Final notification
        let finalContent = UNMutableNotificationContent()
        finalContent.title = "Haptic Timer"
        finalContent.body = "Timer finished!"
        finalContent.sound = .default

        let finalTrigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(timeRemaining),
            repeats: false
        )

        let finalRequest = UNNotificationRequest(
            identifier: "timer-finished",
            content: finalContent,
            trigger: finalTrigger
        )

        UNUserNotificationCenter.current().add(finalRequest)
    }
}

#if os(watchOS)
    // Add extension for HKWorkoutSession delegate
    extension HapticTimerViewModel: HKWorkoutSessionDelegate {
        func workoutSession(
            _ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
            from fromState: HKWorkoutSessionState, date: Date
        ) {
            print("Workout session state changed to: \(toState.rawValue)")

            if toState == .ended {
                print("Workout session ended")
            }
        }

        func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
            print("Workout session failed with error: \(error)")

            DispatchQueue.main.async {
                if self.isRunning {
                    // Try to restart session immediately
                    self.startWorkoutSession()

                    // If that fails, fall back to local notifications
                    if self.workoutSession == nil {
                        self.scheduleLocalNotifications()
                    }
                }
            }
        }
    }
#endif
