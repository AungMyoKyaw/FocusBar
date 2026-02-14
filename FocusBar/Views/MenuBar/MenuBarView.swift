import SwiftUI
import SwiftData

struct MenuBarView: View {
    @Environment(\.modelContext) private var modelContext
    @State var timerViewModel: TimerViewModel

    var body: some View {
        VStack(spacing: 12) {
            if let error = timerViewModel.currentError {
                ErrorBannerView(error: error) {
                    timerViewModel.currentError = nil
                }
            }
            headerSection
            timerSection
            controlsSection
            Divider()
            XPProgressView(
                currentXP: timerViewModel.gamificationViewModel.currentXP,
                currentLevel: timerViewModel.gamificationViewModel.currentLevel,
                levelTitle: timerViewModel.gamificationViewModel.levelTitle,
                xpProgress: timerViewModel.gamificationViewModel.xpProgress,
                currentStreak: timerViewModel.gamificationViewModel.currentStreak
            )
            Divider()
            navigationSection
        }
        .padding()
        .frame(width: 280)
        .onAppear {
            timerViewModel.modelContext = modelContext
        }
    }

    private var headerSection: some View {
        HStack {
            Text("FocusBar")
                .font(.headline)
            Spacer()
            if timerViewModel.timerState != .idle {
                Text(timerViewModel.currentSessionType.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Current session: \(timerViewModel.currentSessionType.displayName)")
            }
        }
    }

    private var timerSection: some View {
        Group {
            if timerViewModel.timerState != .idle {
                VStack(spacing: 8) {
                    Text(timerViewModel.formattedTime)
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                        .foregroundStyle(timerViewModel.timerState == .paused ? .secondary : .primary)
                        .accessibilityLabel("Time remaining: \(timerViewModel.formattedTime)")
                        .accessibilityValue(timerViewModel.timerState == .paused ? "Paused" : "Running")

                    Text("Session \(timerViewModel.completedPomodorosInCycle + 1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Session \(timerViewModel.completedPomodorosInCycle + 1) of cycle")
                }
            }
        }
    }

    private var controlsSection: some View {
        Group {
            if timerViewModel.timerState == .idle {
                Button {
                    timerViewModel.startFocus()
                } label: {
                    Label("Start Focus", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityHint("Starts a new focus session")
            } else {
                HStack(spacing: 12) {
                    Button {
                        timerViewModel.togglePauseResume()
                    } label: {
                        Label(
                            timerViewModel.timerState == .paused ? "Resume" : "Pause",
                            systemImage: timerViewModel.timerState == .paused ? "play.fill" : "pause.fill"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .accessibilityLabel(timerViewModel.timerState == .paused ? "Resume timer" : "Pause timer")
                    .accessibilityHint(timerViewModel.timerState == .paused ? "Resumes the current session" : "Pauses the current session")

                    Menu {
                        Button("Skip") { timerViewModel.skip() }
                        Button("Reset", role: .destructive) { timerViewModel.reset() }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("More actions")
                    .accessibilityHint("Skip or reset the current session")
                }
            }
        }
    }

    @Environment(\.openWindow) private var openWindow

    private var navigationSection: some View {
        VStack(spacing: 4) {
            Button("Statistics") { openWindow(id: "stats") }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the statistics window")
            Button("Achievements") { openWindow(id: "achievements") }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the achievements window")
            Button("Settings...") { openWindow(id: "settings") }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the settings window")
            Divider()
            Button("Quit FocusBar") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Quits the application")
        }
    }
}
