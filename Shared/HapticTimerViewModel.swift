import Combine
import Foundation
import SwiftUI

// import WatchKit

class HapticTimerViewModel: NSObject, ObservableObject {
    @Published var timeRemaining: Int = 60
    @Published var isRunning = false
    @AppStorage("initialtime") var initialTime: TimeInterval = 60

    private var endDate: Date?
    private var lastUpdateTime: Date?
    private var updateTimer: Timer?
    private let hapticService = HapticService.shared

    override init() {
        super.init()
        timeRemaining = Int(initialTime)
    }

    var startButtonText: String {
        if isRunning {
            return "Pause"
        } else {
            if timeRemaining > 0 && timeRemaining < Int(initialTime) {
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
#endif

        // Start a timer to update the UI every second
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateTime()
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
    }

    func stopTimer() {
        isRunning = false
        updateTimer?.invalidate()
        updateTimer = nil
        endDate = nil
        lastUpdateTime = nil
        timeRemaining = Int(initialTime)
#if os(watchOS)
        endExtendedSession()
#endif
    }

#if os(watchOS)
    private func startExtendedSession() {
        // End any existing session
        endExtendedSession()

        // Create and start new session
        extendedSession = WKExtendedRuntimeSession()
        extendedSession?.delegate = self
        extendedSession?.start()
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

        // If session was invalidated but timer should still be running, try to start a new session
        DispatchQueue.main.async {
            if self.isRunning, self.extendedSession == nil {
                self.startExtendedSession()
            }
        }
    }
}
#endif
