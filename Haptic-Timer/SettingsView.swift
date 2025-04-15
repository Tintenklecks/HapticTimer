import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    @ObservedObject var viewModel: HapticTimerViewModel
    @StateObject private var settingsViewModel = SettingsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SectionHeader(title: "Haptic Feedback for ...")
                
                ForEach(Intervals.allCases.reversed(), id: \.rawValue) { interval in
                    Toggle(isOn: Binding(
                        get: { interval.isActive },
                        set: { interval.setActive($0) }
                    )) {
                        Text("\(interval.name)")
                    }
                    .padding(.horizontal)
                }
                
                // Font Settings Section
                SectionHeader(title: "Font Settings")
                    .padding(.top, 20)
                
                HStack {
                    Text("Font:")
                    Spacer()
                    Picker("Font", selection: $settingsViewModel.selectedFont) {
                        ForEach(settingsViewModel.availableFonts, id: \.self) { font in
                            Text(font).tag(font)
                        }
                    }
                }
                .padding(.horizontal)
                
                HStack {
                    Text("Font Size: \(Int(settingsViewModel.fontSize))")
                    Spacer()
                    Button(action: { settingsViewModel.decreaseFontSize() }) {
                        Image(systemName: "minus.circle")
                    }
                    Button(action: { settingsViewModel.increaseFontSize() }) {
                        Image(systemName: "plus.circle")
                    }
                }
                .padding(.horizontal)
                
                
                
                Text("01:23")
                    .font(
                        .custom(
                            appState.fontName,
                            size: appState.fontSize * appState
                                .scale)
                    )
                    .foregroundColor(.white)
                    .padding(.vertical)
                
                Text("v \(settingsViewModel.appVersion).\(settingsViewModel.buildNumber)")
                    .font(.caption2)
                    .padding(.top, 40)
            }.padding()
        }
        .font(.system(size: 24, weight: .regular))
        .background(Color.backgroundColor)
        .foregroundColor(.foregroundColor)
        .navigationTitle("Settings")
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.actionColor)
            Spacer()
        }
        .padding(.bottom)
    }
}

#Preview {
    SettingsView(viewModel: HapticTimerViewModel())
        .environmentObject(AppState())
}
