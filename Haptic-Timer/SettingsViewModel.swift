import SwiftUI

class SettingsViewModel: ObservableObject {
    
    let availableFonts: [String]
    let appVersion: String
    let buildNumber: String
    
    
    init() {
        self.availableFonts = UIFont.familyNames.sorted()
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?.?"
        self.buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }
    
}

// Keys enum for UserDefaults
enum Keys: String {
    case selectedFont
    case fontSize
}
