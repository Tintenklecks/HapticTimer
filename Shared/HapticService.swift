import Foundation
#if os(watchOS)
import WatchKit
#else
import UIKit
#endif

class HapticService {
    static let shared = HapticService()
    
    #if os(iOS) || os(iPadOS)
    private var impactGenerator: UIImpactFeedbackGenerator?
    private var notificationGenerator: UINotificationFeedbackGenerator?
    #endif
    
    private init() {}
    
    func playHaptic(for secondsRemaining: Int) {
        #if os(watchOS)
        if let hapticType = hapticFeedbackType(for: secondsRemaining) {
            WKInterfaceDevice.current().play(hapticType)
        }
        #else
        if secondsRemaining == 1 {
            playNotificationHaptic(.success)
        } else if secondsRemaining % 60 == 0 {
            playImpactHaptic(.heavy)
        } else if secondsRemaining % 10 == 0 {
            playImpactHaptic(.medium)
        } else if secondsRemaining % 5 == 0 {
            playImpactHaptic(.light)
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
        impactGenerator = UIImpactFeedbackGenerator(style: style)
        impactGenerator?.prepare()
        impactGenerator?.impactOccurred()
        impactGenerator = nil
    }
    
    private func playNotificationHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator?.prepare()
        notificationGenerator?.notificationOccurred(type)
        notificationGenerator = nil
    }
    #endif
} 