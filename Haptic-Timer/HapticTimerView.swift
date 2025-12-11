import SwiftUI

struct HapticTimerView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel = HapticTimerViewModel()

    @AppStorage("initialtime") var initialTime: TimeInterval = 60
    
    @State private var showWatchInfo = true
    @AppStorage("watchInfoShown") var watchInfoShown: Int = 0

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.backgroundColor.ignoresSafeArea()

                VStack {
                    HStack {
                        Spacer()
                        VStack {
                            Text("\n\nAlso available as")

                            Image(systemName: "applewatch.radiowaves.left.and.right")
                                .symbolEffect(
                                    .variableColor.cumulative.dimInactiveLayers.reversing,
                                    options: .repeat(.continuous)
                                )
                                .padding(4)
                                .font(.system(size: 24))

                            Text("**Watch App**")
                        }
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                watchInfoShown += 1
                                showWatchInfo.toggle()
                            }
                        }
                    }
                    .padding()
                    .opacity(showWatchInfo && watchInfoShown < 3 ? 1 : 0)
                    // .offset(y: 60)
                    .font(.caption)

                    Spacer()

                    Text(timeString(from: viewModel.timeRemaining))
                        .font(
                            .custom(
                                appState.fontName,
                                size: appState.fontSize
                                    * appState
                                    .scale
                            )
                        )
                        .foregroundColor(.white)
                        .padding(.vertical)

                    Spacer()

                    if viewModel.showResetButton {
                        BottomButton(title: viewModel.resetButtonText) {
                            viewModel.resetButtonAction()
                        }
                        .padding(.bottom, -30)  // Ignore safe area
                    } else {
                        HStack(spacing: 8) {
                            BottomButton(title: viewModel.startButtonText) {
                                viewModel.startButtonAction()
                            }

                            BottomButton(title: viewModel.stopButtonText, isPrimary: false) {
                                viewModel.stopButtonAction()
                            }
                        }
                        .padding(.bottom, -30)  // Ignore safe area
                    }
                }
            }
            .foregroundStyle(.white)
            .navigationTitle("Haptic Countdown")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !viewModel.isRunning {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink(destination: SettingsView(viewModel: viewModel)) {
                            Image(systemName: "gear")
                                .foregroundColor(.white)
                        }
                    }
                }
//                .opacity(viewModel.isRunning ? 0 : 1)
            }
            .onChange(of: initialTime) {
                if !viewModel.isRunning {
                    viewModel.setTime(initialTime)
                }
            }
            .alert(
                "Enable Notifications", isPresented: $viewModel.showNotificationExplanationDialog
            ) {
                Button("Allow") {
                    viewModel.requestNotificationPermissionAfterExplanation()
                }
                Button("Cancel", role: .cancel) {
                    viewModel.cancelNotificationPermissionRequest()
                }
            } message: {
                Text(
                    "To keep your WatchOS app running and deliver haptic feedback even when your watch goes to sleep, this app needs notification permissions. This ensures your timer continues working in the background."
                )
            }
            .alert("Feedback Unavailable", isPresented: $viewModel.showFeedbackAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(
                    "Your device supports neither haptic feedback nor sound playback. Please ensure your volume is up and Silent Mode is off."
                )
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
        .environmentObject(AppState())
}
