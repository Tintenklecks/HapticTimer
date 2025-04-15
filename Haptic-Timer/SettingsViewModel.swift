import SwiftUI

class SettingsViewModel: ObservableObject {
    @AppStorage("selectedFont") var selectedFont: String = UIFont.familyNames[0]
    @AppStorage("fontSize") var fontSize: Double = 16
    
    let availableFonts: [String]
    let appVersion: String
    let buildNumber: String
    
    private let minFontSize: CGFloat = 8
    private let maxFontSize: CGFloat = 128
    private let fontSizeStep: CGFloat = 2
    
    init() {
        self.availableFonts = UIFont.familyNames.sorted()
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?.?"
        self.buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }
    
    func increaseFontSize() {
        fontSize = min(fontSize + fontSizeStep, maxFontSize)
    }
    
    func decreaseFontSize() {
        fontSize = max(fontSize - fontSizeStep, minFontSize)
    }
}

// Keys enum for UserDefaults
enum Keys: String {
    case selectedFont
    case fontSize
}
