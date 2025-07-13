import SwiftUI
#if os(watchOS)
import WatchKit
#endif

struct HapticTimerView: View {
    @EnvironmentObject var appState: AppState

    @ObservedObject var viewModel = HapticTimerViewModel()
    @AppStorage("initialtime") var initialTime: TimeInterval = 60
    var timeHeight: Double {
        appState.scaled(64)
    }
    
    init(    ) {
        
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack {
                HStack {
                    Text("HapticTimer")
                        .font(.headline)
                        .foregroundColor(.actionColor)
                    Spacer()
                    Image(systemName: "gear")
                        .foregroundColor(.white)
                        .imageScale(.large)
                        .onTapGesture {
                            appState.path.append("SettingsView")
                        }
                        .offset(x: -12, y: 8)
                }
                Spacer()

                Text(timeString(from: viewModel.timeRemaining))
                    .font(
                        .system(
                            size: timeHeight,
                            weight: .regular
                        ) // , design: .monospaced)
                    )
                    .foregroundColor(.white)
                    .padding(.vertical)

                Spacer()

                if viewModel.showResetButton {
                    BottomButton(viewModel.resetButtonText) {
                        viewModel.resetButtonAction()
                    }

                } else {
                    HStack {
                        BottomButton(viewModel.startButtonText) {
                            viewModel.startButtonAction()
                        }
                        Text(" ")
                        BottomButton(viewModel.stopButtonText, isPrimary: false) {
                            viewModel.stopButtonAction()
                        }
                    }
                }

                Spacer()
            }
            .background(Color.backgroundColor)
            .focusable(true)
            .digitalCrownRotation(
                $initialTime,
                from: 1,
                through: 3600,
                by: 1,
                sensitivity: .low,
                isContinuous: false,
                isHapticFeedbackEnabled: true
            )
            .onChange(of: initialTime) {
                if !viewModel.isRunning {
                    viewModel.setTime(initialTime)
                }
            }
            .navigationDestination(for: String.self) { value in
                if value == "SettingsView" {
                    SettingsView(viewModel: viewModel)
                }
            }
            #if os(watchOS)
            // Keep the timer view active when running
            .onReceive(NotificationCenter.default.publisher(for: WKApplication.didBecomeActiveNotification)) { _ in
                print("App became active")
            }
            .onReceive(NotificationCenter.default.publisher(for: WKApplication.willResignActiveNotification)) { _ in
                print("App will resign active")
                // The extended runtime session should keep the timer running
            }
            #endif
            .alert("Enable Notifications", isPresented: $viewModel.showNotificationExplanationDialog) {
                Button("Allow") {
                    viewModel.requestNotificationPermissionAfterExplanation()
                }
                Button("Cancel", role: .cancel) {
                    viewModel.cancelNotificationPermissionRequest()
                }
            } message: {
                Text("To keep your WatchOS app running and deliver haptic feedback even when your watch goes to sleep, this app needs notification permissions. This ensures your timer continues working in the background.")
            }
        }
    }

    func timeString(from timerSeconds: Int) -> String {
        let minutes = timerSeconds / 60
        let seconds = timerSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    HapticTimerView()
}
