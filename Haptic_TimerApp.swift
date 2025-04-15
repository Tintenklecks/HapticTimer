import SwiftUI

@main
struct Haptic_Timer_Watch_AppApp: App {
    @StateObject var appState = AppState()
    @AppStorage("initialtime") var initialTime: TimeInterval = 60
    
    init() {
        print("initialTime: \(initialTime)")
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $appState.path) {
                HapticTimerView()
//                AllFonts()
            }
        }
        .environmentObject(appState)
    }
}
