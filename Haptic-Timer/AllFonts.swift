import SwiftUI

struct AllFonts: View {
    @StateObject private var viewModel = AllFontsViewModel()
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(viewModel.fonts, id: \.self) { fontName in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(fontName)
                            .font(.headline)
                        
                        Text("The quick brown fox jumps over the lazy dog")
                            .font(.custom(fontName, size: viewModel.fontSize))
                    }
                    .padding(.horizontal)
                    Divider()
                }
            }
        }
        .navigationTitle("Available Fonts")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { viewModel.decreaseFontSize() }) {
                    Image(systemName: "minus.circle")
                }
                
                Text("\(Int(viewModel.fontSize))")
                    .frame(minWidth: 30)
                
                Button(action: { viewModel.increaseFontSize() }) {
                    Image(systemName: "plus.circle")
                }
            }
        }
    }
}

class AllFontsViewModel: ObservableObject {
    @Published var fonts: [String]
    @Published var fontSize: CGFloat = 16
    
    private let minFontSize: CGFloat = 8
    private let maxFontSize: CGFloat = 40
    private let fontSizeStep: CGFloat = 2
    
    init() {
        // Get all available font names from the system
        self.fonts = UIFont.familyNames.sorted()
    }
    
    func increaseFontSize() {
        fontSize = min(fontSize + fontSizeStep, maxFontSize)
    }
    
    func decreaseFontSize() {
        fontSize = max(fontSize - fontSizeStep, minFontSize)
    }
}

#Preview {
    NavigationView {
        AllFonts()
    }
}


