import Foundation
#if os(watchOS)
import WatchKit
#else
import UIKit
import AVFoundation
#endif

class HapticService {
    static let shared = HapticService()
    
    #if os(iOS) || os(iPadOS)
    private var impactGenerator: UIImpactFeedbackGenerator?
    private var notificationGenerator: UINotificationFeedbackGenerator?
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    #endif
    
    private init() {
        #if os(iOS) || os(iPadOS)
        setupAudioPlayers()
        #endif
    }
    
    #if os(iOS) || os(iPadOS)
    private func setupAudioPlayers() {
        // Load different sound files for different intervals
        let soundFiles = [
            "tick_1s": "tick_1s.wav",    // Lightest sound for 1-second intervals
            "tick_5s": "tick_5s.wav",    // Light sound for 5-second intervals
            "tick_10s": "tick_10s.wav",  // Medium sound for 10-second intervals
            "tick_60s": "tick_60s.wav",  // Strongest sound for minute intervals
            "tick_end": "tick_end.wav"   // Special sound for timer end
        ]
        
        for (key, filename) in soundFiles {
            guard let soundURL = Bundle.main.url(forResource: filename, withExtension: nil) else {
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
                    player.volume = 0.1   // 10% volume for 5-second intervals
                case "tick_10s":
                    player.volume = 0.2   // 20% volume for 10-second intervals
                case "tick_60s":
                    player.volume = 0.3   // 30% volume for minute intervals
                case "tick_end":
                    player.volume = 0.4   // 40% volume for timer end
                default:
                    player.volume = 0.1   // Default volume
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
        if secondsRemaining == 1 {
            playNotificationHaptic(.success)
            playSound("tick_1s")
        } else if secondsRemaining % 60 == 0, Intervals.oneMinute.isActive {
            playImpactHaptic(.heavy)
            playSound("tick_60s")
        } else if secondsRemaining % 10 == 0, Intervals.tenSeconds.isActive {
            playImpactHaptic(.medium)
            playSound("tick_10s")
        } else if secondsRemaining % 5 == 0, Intervals.fiveSeconds.isActive {
            playImpactHaptic(.light)
            playSound("tick_5s")
        } else if Intervals.oneSecond.isActive {
            playImpactHaptic(.light)
            playSound("tick_1s")
        }
        #endif
    }
    
    func playTimerEndHaptic() {
        #if os(watchOS)
        let hapticType = WKHapticType.retry
        DispatchQueue.main.async {
            for i in 0 ..< 3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7 * Double(i)) {
                    WKInterfaceDevice.current().play(hapticType)
                }
            }
        }
        #else
        playNotificationHaptic(.error)
        playSound("tick_end")
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
    
    private func playSound(_ key: String) {
        DispatchQueue.main.async {
            if let player = self.audioPlayers[key] {
                player.currentTime = 0
                player.play()
            }
        }
    }
    #endif
} 