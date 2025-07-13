import Combine
import Foundation
import SwiftUI
import UserNotifications

#if os(watchOS)
import WatchKit
#endif

class HapticTimerViewModel: NSObject, ObservableObject {
    @Published var timeRemaining: Int = 60
    @Published var isRunning = false
    @Published var showNotificationExplanationDialog = false
    @AppStorage("initialtime") var initialTime: TimeInterval = 60
    @AppStorage("hasShownNotificationExplanation") private var hasShownNotificationExplanation = false
    
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
    private var extendedSession: WKExtendedRuntimeSession?
#endif

    func startTimer() {
        guard !isRunning else { return }
        isRunning = true

        // Calculate end date based on current time and remaining time
        endDate = Date().addingTimeInterval(TimeInterval(timeRemaining))
        lastUpdateTime = Date()

#if os(watchOS)
        startExtendedSession()
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
        endExtendedSession()
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
        endExtendedSession()
#endif
        
        // Clear scheduled notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

#if os(watchOS)
    private func startExtendedSession() {
        // End any existing session
        endExtendedSession()

        // Create and start new session
        extendedSession = WKExtendedRuntimeSession()
        extendedSession?.delegate = self
        extendedSession?.start(at: Date())
        
        print("Starting extended runtime session")
    }

    private func endExtendedSession() {
        extendedSession?.invalidate()
        extendedSession = nil
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
        let intervals = [1, 5, 10, 60] // seconds
        
        for interval in intervals.reversed() {
            if timeRemaining >= interval {
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
// Add extension for WKExtendedRuntimeSession delegate
extension HapticTimerViewModel: WKExtendedRuntimeSessionDelegate {
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("Extended runtime session started")
    }

    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("Extended runtime session will expire")
    }

    func extendedRuntimeSession(
        _ extendedRuntimeSession: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?
    ) {
        print("Extended runtime session invalidated with reason: \(reason)")

        DispatchQueue.main.async {
            if self.isRunning {
                // Try to restart session immediately
                self.startExtendedSession()
                
                // If that fails, fall back to local notifications
                if self.extendedSession == nil {
                    self.scheduleLocalNotifications()
                }
            }
        }
    }
}
#endif
