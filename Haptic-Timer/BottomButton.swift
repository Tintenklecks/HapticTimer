import SwiftUI


struct BottomButton: View {
    let title: String
    let action: () -> Void
    let isPrimary: Bool
    
    init(title: String, isPrimary: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isPrimary = isPrimary
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isPrimary ? Color.startBG : Color.stopBG)
//                .cornerRadius(12)
        }
        .frame(width: UIScreen.main.bounds.width * 0.49)
        .frame(height: UIScreen.main.bounds.height * 0.25)
    }
}
#Preview {
    BottomButton(title: "Hallo Start") {
        print("dfgdfgdf")
    }
}
