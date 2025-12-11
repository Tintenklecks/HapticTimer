import Foundation

#if os(watchOS)
    import WatchKit
#else
    import UIKit
    import AVFoundation
    import CoreHaptics
#endif

class HapticService {
    static let shared = HapticService()

    #if os(iOS) || os(iPadOS)
        private var impactGenerator: UIImpactFeedbackGenerator?
        private var notificationGenerator: UINotificationFeedbackGenerator?
        private var audioPlayers: [String: AVAudioPlayer] = [:]
        private var engine: CHHapticEngine?

        var onFeedbackFailed: (() -> Void)?

        private var supportsHaptics: Bool {
            CHHapticEngine.capabilitiesForHardware().supportsHaptics
        }
    #endif

    private init() {
        #if os(iOS) || os(iPadOS)
            setupAudioPlayers()
            createEngine()
        #endif
    }

    #if os(iOS) || os(iPadOS)
        private func setupAudioPlayers() {
            // Load different sound files for different intervals
            let soundFiles = [
                "tick_1s": "tick_1s.wav",  // Lightest sound for 1-second intervals
                "tick_5s": "tick_5s.wav",  // Light sound for 5-second intervals
                "tick_10s": "tick_10s.wav",  // Medium sound for 10-second intervals
                "tick_60s": "tick_60s.wav",  // Strongest sound for minute intervals
                "tick_end": "tick_end.wav",  // Special sound for timer end
            ]

            for (key, filename) in soundFiles {
                guard let soundURL = Bundle.main.url(forResource: filename, withExtension: nil)
                else {
                    print("Could not find sound file: \(filename)")
                    continue
                }

                do {
                    let player = try AVAudioPlayer(contentsOf: soundURL)
                    player.prepareToPlay()

                    // Set different volumes for different intervals
                    switch key {
                    case "tick_1s":
                        player.volume = 0.05  // 5% volume for 1-second intervals
                    case "tick_5s":
                        player.volume = 0.1  // 10% volume for 5-second intervals
                    case "tick_10s":
                        player.volume = 0.2  // 20% volume for 10-second intervals
                    case "tick_60s":
                        player.volume = 0.3  // 30% volume for minute intervals
                    case "tick_end":
                        player.volume = 0.4  // 40% volume for timer end
                    default:
                        player.volume = 0.1  // Default volume
                    }

                    audioPlayers[key] = player
                } catch {
                    print("Could not create audio player for \(filename): \(error)")
                }
            }
        }
    #endif

    func playHaptic(for secondsRemaining: Int) {
        #if os(watchOS)
            if let hapticType = hapticFeedbackType(for: secondsRemaining) {
                WKInterfaceDevice.current().play(hapticType)
            }
        #else
            if supportsHaptics {
                // Priority 1: Haptics
                if secondsRemaining == 1 {
                    playNotificationHaptic(.success)
                } else if secondsRemaining % 60 == 0, Intervals.oneMinute.isActive {
                    playCustomHaptic(intensity: 1.0, sharpness: 1.0)  // Strongest possible transient
                } else if secondsRemaining % 10 == 0, Intervals.tenSeconds.isActive {
                    playImpactHaptic(.medium)
                } else if secondsRemaining % 5 == 0, Intervals.fiveSeconds.isActive {
                    playImpactHaptic(.light)
                } else if Intervals.oneSecond.isActive {
                    playImpactHaptic(.light)
                }
            } else {
                // Priority 2: Sound (Fallback)
                var soundKey: String?

                if secondsRemaining == 1 {
                    soundKey = "tick_1s"
                } else if secondsRemaining % 60 == 0, Intervals.oneMinute.isActive {
                    soundKey = "tick_60s"
                } else if secondsRemaining % 10 == 0, Intervals.tenSeconds.isActive {
                    soundKey = "tick_10s"
                } else if secondsRemaining % 5 == 0, Intervals.fiveSeconds.isActive {
                    soundKey = "tick_5s"
                } else if Intervals.oneSecond.isActive {
                    soundKey = "tick_1s"
                }

                if let key = soundKey {
                    let success = playSound(key)
                    if !success {
                        // Priority 3: Alert (Both failed)
                        DispatchQueue.main.async {
                            self.onFeedbackFailed?()
                        }
                    }
                }
            }
        #endif
    }

    func playTimerEndHaptic() {
        #if os(watchOS)
            let hapticType = WKHapticType.retry
            DispatchQueue.main.async {
                for i in 0..<3 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7 * Double(i)) {
                        WKInterfaceDevice.current().play(hapticType)
                    }
                }
            }
        #else
            if supportsHaptics {
                playCustomHaptic(intensity: 1.0, sharpness: 1.0)
                // Play a second one for emphasis
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.playCustomHaptic(intensity: 1.0, sharpness: 0.5)
                }
            } else {
                let success = playSound("tick_end")
                if !success {
                    DispatchQueue.main.async {
                        self.onFeedbackFailed?()
                    }
                }
            }
        #endif
    }

    #if os(watchOS)
        private func hapticFeedbackType(for secondsRemaining: Int) -> WKHapticType? {
            if secondsRemaining == 1 {
                return .start
            } else if secondsRemaining % 60 == 0 {
                return .failure
            } else if secondsRemaining % 10 == 0 {
                return .retry
            } else if secondsRemaining % 5 == 0 {
                return .directionDown
            }
            return nil
        }
    #else
        private func createEngine() {
            guard supportsHaptics else { return }
            do {
                engine = try CHHapticEngine()
                try engine?.start()
            } catch {
                print("There was an error creating the engine: \(error.localizedDescription)")
            }
        }

        private func playCustomHaptic(intensity: Float, sharpness: Float) {
            guard supportsHaptics else { return }

            // Restart engine if needed
            do {
                try engine?.start()
            } catch {
                print("Failed to restart engine: \(error)")
            }

            let hapticEvent = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
                ],
                relativeTime: 0
            )

            do {
                let pattern = try CHHapticPattern(events: [hapticEvent], parameters: [])
                let player = try engine?.makePlayer(with: pattern)
                try player?.start(atTime: 0)
            } catch {
                print("Failed to play custom haptic: \(error)")
            }
        }

        private func playImpactHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
            DispatchQueue.main.async {
                self.impactGenerator = UIImpactFeedbackGenerator(style: style)
                self.impactGenerator?.prepare()
                self.impactGenerator?.impactOccurred()
                self.impactGenerator = nil
            }
        }

        private func playNotificationHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
            DispatchQueue.main.async {
                self.notificationGenerator = UINotificationFeedbackGenerator()
                self.notificationGenerator?.prepare()
                self.notificationGenerator?.notificationOccurred(type)
                self.notificationGenerator = nil
            }
        }

        private func playSound(_ key: String) -> Bool {
            if let player = audioPlayers[key] {
                player.currentTime = 0
                return player.play()
            }
            return false
        }
    #endif
}
