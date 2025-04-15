
import Foundation

enum Intervals: Int {
    case oneSecond = 1
    case fiveSeconds = 5
    case tenSeconds = 10
    case oneMinute = 60
    
    static var allCases: [Intervals] {
        return [.oneSecond, .fiveSeconds, .tenSeconds, .oneMinute].reversed()
    }
    
    var name: String {
        switch self {
        case .oneSecond:
            return "1 Second"
        case .fiveSeconds:
            return "5 Seconds"
        case .tenSeconds:
            return "10 Seconds"
        case .oneMinute:
            return "1 Minute"
        }
    }
    
    var isActive: Bool {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "interval\(self.rawValue)") == nil {
            return true
        } else {
            return defaults.bool(forKey: "interval\(self.rawValue)")
        }
    }
    
    func setActive(_ value: Bool) {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: "interval\(self.rawValue)")
    }
}
