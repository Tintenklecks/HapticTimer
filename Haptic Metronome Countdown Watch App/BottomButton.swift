import SwiftUI
//import WatchKit

struct BottomButton: View {
    @EnvironmentObject var appState: AppState

    let text: String
    let isPrimary: Bool
    let action: () -> Void

    var buttonHeight: Double {
        appState.scaled(50)
    }

    @State private var isPressed: Bool = false

    init(_ text: String, isPrimary: Bool = true, action: @escaping () -> Void) {
        self.text = text
        self.isPrimary = isPrimary
        self.action = action
    }

    var color: Color {
        isPrimary ? .orange : .white.opacity(0.1)
    }

    var body: some View {
        HStack {
            Spacer()
            Text(text)
                .offset(y: appState.scaled(
                    isPressed ? 14.0 : 12.0)
                )
            Spacer()
        }
        .frame(height: buttonHeight)
        .background(color.opacity(isPressed ? 0.7 : 0.9))
        .onTapGesture {
            isPressed.toggle()
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isPressed = false
            }
        }
    }
}

#Preview {
    BottomButton("Start", isPrimary: true, action: {})
}
