import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: HapticTimerViewModel

    let appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?.?"

    let buildNumber: String = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"

    var body: some View {
        ScrollView {
            HStack {
                Text("Haptic Feedback for ...")
                    .font(.headline)
                    .foregroundStyle(Color.actionColor)
                Spacer()
            }
            .padding(.bottom)

            /* DEMO TEST
            let all: [WKHapticType] = [
                .notification, // 0
                .directionUp, // 1
                .directionDown, // 2
                .success, // 3
                .failure,   // 4
                .retry, // 5
                .start,     // 6
                .stop,    // 7
                .click  // 8
            ]

            // Display ech haptic type in a button
            ForEach(all, id: \.self) { hapticType in
                Button {
                    WKInterfaceDevice.current().play(hapticType)
                } label: {
                    Text("\(hapticType.rawValue)")
                }
            }
            
             DEMO TEST */

            ForEach(Intervals.allCases.reversed(), id: \.rawValue) { interval in
                // Create a toggle for each interval
                Toggle(isOn: Binding(
                    get: {
                        interval.isActive
                    },
                    set: {
                        interval.setActive($0)
                    })) {
                        Text("\(interval.name)")
                    }
                    .padding(.horizontal)
            }

            Text("v \(appVersion).\(buildNumber)")
                .font(.caption2)
                .padding(.top)
        }
        .background(Color.backgroundColor)
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView(viewModel: HapticTimerViewModel())
}
