import SwiftUI
import SwiftData

struct MenuBarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(UserDefaultsKeys.sessionsUntilLongBreak) private var sessionsUntilLongBreak = Constants.defaultSessionsUntilLongBreak
    @State var timerViewModel: TimerViewModel

    private var activeAccent: Color {
        FocusBarTheme.accent(for: timerViewModel.currentSessionType)
    }

    var body: some View {
        VStack(spacing: 12) {
            if let error = timerViewModel.displayError {
                ErrorBannerView(error: error) {
                    timerViewModel.clearError()
                }
            }

            headerSection
            timerRingSection
            controlsSection

            Divider()

            ReminderPicker(viewModel: timerViewModel.remindersViewModel)

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
        .padding(14)
        .frame(width: 300)
        .onAppear {
            timerViewModel.modelContext = modelContext
        }
    }

    private var headerSection: some View {
        HStack(spacing: 8) {
            Text("FocusBar")
                .font(.headline)

            if timerViewModel.timerState != .idle {
                Text(timerViewModel.currentSessionType.displayName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(activeAccent)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(activeAccent.opacity(0.14), in: Capsule())
                    .accessibilityLabel("Current session: \(timerViewModel.currentSessionType.displayName)")
            }

            Spacer()

            cycleDots
        }
    }

    private var cycleDots: some View {
        let total = max(1, sessionsUntilLongBreak)
        return HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index < timerViewModel.completedPomodorosInCycle ? activeAccent : Color.secondary.opacity(0.25))
                    .frame(width: 6, height: 6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(timerViewModel.completedPomodorosInCycle) of \(total) focus sessions in cycle")
    }

    private var timerRingSection: some View {
        let isIdle = timerViewModel.timerState == .idle
        let progress = isIdle ? 0 : timerViewModel.sessionProgress
        let timeText = isIdle ? timerViewModel.configuredDurationFormatted : timerViewModel.formattedTime

        return ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.16), lineWidth: FocusBarTheme.ringLineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    activeAccent,
                    style: StrokeStyle(lineWidth: FocusBarTheme.ringLineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .linear(duration: 0.25), value: progress)

            VStack(spacing: 2) {
                Text(timeText)
                    .font(.system(size: 34, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(timerViewModel.timerState == .paused ? .secondary : .primary)

                Text(statusCaption)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: FocusBarTheme.ringSize, height: FocusBarTheme.ringSize)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isIdle ? "Ready: \(timeText)" : "Time remaining: \(timeText)")
        .accessibilityValue(statusCaption)
    }

    private var statusCaption: String {
        switch timerViewModel.timerState {
        case .idle:
            return "Ready for \(timerViewModel.currentSessionType.displayName)"
        case .running:
            return "Session \(timerViewModel.completedPomodorosInCycle + 1)"
        case .paused:
            return "Paused"
        }
    }

    private var controlsSection: some View {
        Group {
            if timerViewModel.timerState == .idle {
                Button {
                    timerViewModel.startFocus()
                } label: {
                    Label("Start \(timerViewModel.currentSessionType.displayName)", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(activeAccent)
                .controlSize(.large)
                .accessibilityHint("Starts a new \(timerViewModel.currentSessionType.displayName.lowercased()) session")
            } else {
                HStack(spacing: 8) {
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
                    .tint(activeAccent)
                    .controlSize(.regular)
                    .accessibilityLabel(timerViewModel.timerState == .paused ? "Resume timer" : "Pause timer")
                    .accessibilityHint(timerViewModel.timerState == .paused ? "Resumes the current session" : "Pauses the current session")

                    Button {
                        timerViewModel.skip()
                    } label: {
                        Image(systemName: "forward.end.fill")
                    }
                    .buttonStyle(.bordered)
                    .help("Skip to next session")
                    .accessibilityLabel("Skip session")
                    .accessibilityHint("Advances to the next session without awarding XP")

                    Button(role: .destructive) {
                        timerViewModel.reset()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .buttonStyle(.bordered)
                    .help("Reset timer")
                    .accessibilityLabel("Reset timer")
                    .accessibilityHint("Resets the current session to idle")
                }
            }
        }
    }

    private var navigationSection: some View {
        VStack(spacing: 2) {
            MenuBarActionRow(title: "Statistics", systemImage: "chart.bar", hint: "Opens the statistics window") {
                openWindow(id: "stats")
                NSApp.activate(ignoringOtherApps: true)
            }
            MenuBarActionRow(title: "Achievements", systemImage: "trophy", hint: "Opens the achievements window") {
                openWindow(id: "achievements")
                NSApp.activate(ignoringOtherApps: true)
            }
            MenuBarActionRow(title: "Settings...", systemImage: "gearshape", hint: "Opens the settings window") {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            }
            Divider()
                .padding(.vertical, 2)
            MenuBarActionRow(title: "Quit FocusBar", systemImage: "power", hint: "Quits the application", isDestructive: true) {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
