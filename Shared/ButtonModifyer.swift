import SwiftUI

struct ButtonModifyer: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.actionColor)
            .foregroundColor(.white)
            .cornerRadius(10)
    }
}

extension View {
    func buttonStyle() -> some View {
        self.modifier(ButtonModifyer())
    }
}
