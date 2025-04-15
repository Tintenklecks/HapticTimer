import SwiftUI

class AppState: ObservableObject {
    @Published var path: [String] = []
    #if os(watchOS)
    var scale = WKInterfaceDevice.current().screenBounds.width / 200.0
    #else
    var scale = 2.0 // UIScreen.main.scale.width / 200.0
    
    #endif
    
    @AppStorage("fontName") var fontName: String = "SF Pro"
    @AppStorage("fontSize") var fontSize: Double = 64
    

    func scaled(_ value: Double) -> Double {
        return value * scale
    }
}
