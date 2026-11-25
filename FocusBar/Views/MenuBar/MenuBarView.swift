import SwiftUI
import SwiftData

struct MenuBarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(UserDefaultsKeys.sessionsUntilLongBreak) private var sessionsUntilLongBreak = Constants.defaultSessionsUntilLongBreak
    @AppStorage(UserDefaultsKeys.pomodoroDuration) private var pomodoroDuration = Constants.defaultPomodoroDuration
    @AppStorage(UserDefaultsKeys.shortBreakDuration) private var shortBreakDuration = Constants.defaultShortBreakDuration
    @AppStorage(UserDefaultsKeys.longBreakDuration) private var longBreakDuration = Constants.defaultLongBreakDuration
    @State var timerViewModel: TimerViewModel
    var onOpenWindow: ((String) -> Void)? = nil

    private var activeAccent: Color {
        FocusBarTheme.accent(for: timerViewModel.currentSessionType)
    }

    var body: some View {
        VStack(spacing: 11) {
            if let error = timerViewModel.displayError {
                ErrorBannerView(error: error) {
                    timerViewModel.clearError()
                }
            }

            if let awaySeconds = timerViewModel.pendingIdleTrimSeconds {
                idleTrimBanner(awaySeconds: awaySeconds)
            }

            if let promptReminder = timerViewModel.completedReminderPrompt {
                reminderCompleteBanner(reminder: promptReminder)
            }

            headerSection
            timerRingSection
            controlsSection
            quickTaskRow

            ReminderPicker(viewModel: timerViewModel.remindersViewModel)

            XPProgressView(
                currentXP: timerViewModel.gamificationViewModel.currentXP,
                xpForNextLevel: timerViewModel.gamificationViewModel.xpForNextLevel,
                currentLevel: timerViewModel.gamificationViewModel.currentLevel,
                levelTitle: timerViewModel.gamificationViewModel.levelTitle,
                xpProgress: timerViewModel.gamificationViewModel.xpProgress,
                currentStreak: timerViewModel.gamificationViewModel.currentStreak,
                accent: activeAccent
            )

            navigationDock
        }
        .padding(14)
        .frame(width: 318)
        .onAppear {
            timerViewModel.modelContext = modelContext
        }
        .contextMenu {
            if timerViewModel.timerState == .idle {
                Button("Start Focus") { timerViewModel.startFocus() }
            } else {
                Button(timerViewModel.timerState == .running ? "Pause" : "Resume") { timerViewModel.togglePauseResume() }
                Button("Extend +5m") { timerViewModel.extendActiveSession(by: 5) }
                Button("Skip Session") { timerViewModel.skip() }
                Button("Reset") { timerViewModel.reset() }
            }
            Divider()
            Button(timerViewModel.isFloatingTimerVisible ? "Hide Floating Timer" : "Show Floating Timer") {
                timerViewModel.toggleFloatingTimer()
            }
        }
    }

    // MARK: - Inline Prompts

    private func idleTrimBanner(awaySeconds: Int) -> some View {
        let mins = max(1, awaySeconds / 60)
        return HStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(.orange)
            Text("Away \(mins)m — trim?")
                .font(.caption.weight(.medium))
            Spacer()
            Button("Trim") { timerViewModel.trimIdleTime() }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .controlSize(.mini)
            Button("Keep") { timerViewModel.dismissIdlePrompt() }
                .buttonStyle(.bordered)
                .controlSize(.mini)
        }
        .padding(8)
        .focusCardSurface()
    }

    private func reminderCompleteBanner(reminder: ReminderItem) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(.green)
            Text("Done \"\(reminder.title)\"?")
                .font(.caption.weight(.medium))
                .lineLimit(1)
            Spacer()
            Button("Complete") { timerViewModel.completeLinkedReminder() }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.mini)
            Button("No") { timerViewModel.dismissReminderPrompt() }
                .buttonStyle(.bordered)
                .controlSize(.mini)
        }
        .padding(8)
        .focusCardSurface()
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 6) {
            if timerViewModel.timerState == .idle {
                modeSelector
            } else {
                activePhasePill
            }

            Spacer(minLength: 4)

            Button {
                timerViewModel.cycleAmbientSound()
            } label: {
                Image(systemName: timerViewModel.ambientSoundMode.symbolName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(timerViewModel.ambientSoundMode == .off ? AnyShapeStyle(.secondary) : AnyShapeStyle(activeAccent))
                    .frame(width: 24, height: 24)
                    .background(Color.primary.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Ambient Sound: \(timerViewModel.ambientSoundMode.displayName)")
            .accessibilityLabel("Cycle ambient sound")

            Button {
                timerViewModel.toggleFloatingTimer()
            } label: {
                Image(systemName: timerViewModel.isFloatingTimerVisible ? "pip.fill" : "pip")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(timerViewModel.isFloatingTimerVisible ? AnyShapeStyle(activeAccent) : AnyShapeStyle(.secondary))
                    .frame(width: 24, height: 24)
                    .background(Color.primary.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Toggle Floating Mini-Timer")
            .accessibilityLabel("Toggle floating mini-timer")

            cycleIndicator
        }
    }

    private var modeSelector: some View {
        HStack(spacing: 2) {
            ForEach(SessionType.allCases, id: \.self) { type in
                let isSelected = timerViewModel.currentSessionType == type
                let label: String = switch type {
                case .pomodoro: "Focus"
                case .shortBreak: "Short"
                case .longBreak: "Long"
                }

                Button {
                    timerViewModel.selectSessionType(type)
                } label: {
                    Text(label)
                        .font(.caption.weight(isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? activeAccent : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            isSelected ? activeAccent.opacity(0.14) : Color.clear,
                            in: Capsule()
                        )
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Switch to \(type.displayName)")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(2)
        .background(Color.primary.opacity(0.06), in: Capsule())
    }

    private var activePhasePill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(activeAccent)
                .frame(width: 6, height: 6)
                .opacity(timerViewModel.timerState == .paused ? 0.45 : 1.0)

            Text(timerViewModel.isOvertime ? "Overtime" : timerViewModel.currentSessionType.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(activeAccent)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(activeAccent.opacity(0.14), in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current session: \(timerViewModel.currentSessionType.displayName)")
    }

    private var cycleIndicator: some View {
        let total = max(1, sessionsUntilLongBreak)
        let completed = timerViewModel.completedPomodorosInCycle

        return HStack(spacing: 4) {
            HStack(spacing: 2.5) {
                ForEach(0..<total, id: \.self) { index in
                    Circle()
                        .fill(index < completed ? activeAccent : Color.primary.opacity(0.18))
                        .frame(width: 4.5, height: 4.5)
                }
            }
            Text("\(completed)/\(total)")
                .font(.caption2.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(completed) of \(total) focus sessions in cycle")
    }

    // MARK: - Chronograph Dial

    private var timerRingSection: some View {
        let isIdle = timerViewModel.timerState == .idle
        let progress = isIdle ? 0 : timerViewModel.sessionProgress
        let timeText = isIdle ? idleDurationFormatted : timerViewModel.formattedTime

        return ZStack {
            if timerViewModel.timerState == .running {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [activeAccent.opacity(0.10), .clear],
                            center: .center,
                            startRadius: 24,
                            endRadius: FocusBarTheme.ringSize * 0.56
                        )
                    )
            }

            ForEach(0..<60, id: \.self) { tick in
                let isMajor = tick % 5 == 0
                Rectangle()
                    .fill(Color.primary.opacity(isMajor ? 0.22 : 0.09))
                    .frame(width: isMajor ? 1.5 : 1, height: isMajor ? 6 : 3.5)
                    .offset(y: -(FocusBarTheme.ringSize / 2) + 12)
                    .rotationEffect(.degrees(Double(tick) * 6))
            }

            Circle()
                .stroke(Color.primary.opacity(0.10), lineWidth: FocusBarTheme.ringLineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    activeAccent,
                    style: StrokeStyle(lineWidth: FocusBarTheme.ringLineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .linear(duration: 0.25), value: progress)

            VStack(spacing: 3) {
                Text(timeText)
                    .font(.system(size: 36, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: !timerViewModel.isOvertime))
                    .foregroundStyle(timerViewModel.timerState == .paused ? .secondary : .primary)

                Text(statusCaption)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(timerViewModel.isOvertime ? AnyShapeStyle(activeAccent) : AnyShapeStyle(.secondary))

                if isIdle {
                    durationNudgeControls
                        .padding(.top, 2)
                } else if !timerViewModel.isOvertime {
                    DurationNudgeButton(label: "+5m", hint: "Extend active session by 5 minutes") {
                        timerViewModel.extendActiveSession(by: 5)
                    }
                    .padding(.top, 2)
                }
            }
        }
        .frame(width: FocusBarTheme.ringSize, height: FocusBarTheme.ringSize)
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isIdle ? "Ready: \(timeText)" : "Time remaining: \(timeText)")
        .accessibilityValue(statusCaption)
    }

    private var idleDurationFormatted: String {
        let minutes: Int = switch timerViewModel.currentSessionType {
        case .pomodoro: pomodoroDuration
        case .shortBreak: shortBreakDuration
        case .longBreak: longBreakDuration
        }
        let safeMinutes = max(1, minutes)
        return String(format: "%02d:00", safeMinutes)
    }

    private var durationNudgeControls: some View {
        HStack(spacing: 8) {
            DurationNudgeButton(label: "-5m", hint: "Decrease duration by 5 minutes") {
                timerViewModel.adjustConfiguredDuration(by: -5)
            }
            DurationNudgeButton(label: "+5m", hint: "Increase duration by 5 minutes") {
                timerViewModel.adjustConfiguredDuration(by: 5)
            }
        }
    }

    private var statusCaption: String {
        if timerViewModel.isOvertime {
            return "OVERTIME"
        }
        switch timerViewModel.timerState {
        case .idle:
            return "READY"
        case .running:
            let total = max(1, sessionsUntilLongBreak)
            let current = min(timerViewModel.completedPomodorosInCycle + 1, total)
            return "SESSION \(current) OF \(total)"
        case .paused:
            return "PAUSED"
        }
    }

    // MARK: - Transport Controls

    @ViewBuilder
    private var controlsSection: some View {
        if #available(macOS 26, *) {
            GlassEffectContainer(spacing: 8) {
                transportControlsRow
            }
        } else {
            transportControlsRow
        }
    }

    @ViewBuilder
    private var transportControlsRow: some View {
        if timerViewModel.timerState == .idle {
            Button {
                timerViewModel.startFocus()
            } label: {
                Label("Start \(timerViewModel.currentSessionType.displayName)", systemImage: "play.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .focusGlassCapsule(tint: activeAccent, interactive: true)
            .keyboardShortcut(.space, modifiers: [])
            .accessibilityHint("Starts a new \(timerViewModel.currentSessionType.displayName.lowercased()) session")
        } else if timerViewModel.isOvertime {
            HStack(spacing: 8) {
                ResetCircleButton {
                    timerViewModel.reset()
                }
                Button {
                    timerViewModel.completeOvertimeSession()
                } label: {
                    Label("Finish & Log", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .focusGlassCapsule(tint: activeAccent, interactive: true)
                .keyboardShortcut(.space, modifiers: [])
            }
        } else {
            HStack(spacing: 8) {
                ResetCircleButton {
                    timerViewModel.reset()
                }

                Button {
                    timerViewModel.togglePauseResume()
                } label: {
                    let isPaused = timerViewModel.timerState == .paused
                    Label(
                        isPaused ? "Resume" : "Pause",
                        systemImage: isPaused ? "play.fill" : "pause.fill"
                    )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isPaused ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .focusGlassCapsule(
                    tint: timerViewModel.timerState == .paused ? activeAccent : nil,
                    interactive: true
                )
                .keyboardShortcut(.space, modifiers: [])
                .accessibilityLabel(timerViewModel.timerState == .paused ? "Resume timer" : "Pause timer")
                .accessibilityHint(timerViewModel.timerState == .paused ? "Resumes the current session" : "Pauses the current session")

                Button {
                    timerViewModel.skip()
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .focusGlassCapsule(interactive: true)
                .keyboardShortcut(.rightArrow, modifiers: .command)
                .help("Skip to next session")
                .accessibilityLabel("Skip session")
                .accessibilityHint("Advances to the next session without awarding XP")
            }
        }
    }

    // MARK: - Quick Task & Tag

    private var quickTaskRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "pencil.line")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("What are you focusing on?", text: $timerViewModel.quickTaskTitle)
                .textFieldStyle(.plain)
                .font(.caption)

            Menu {
                Button("No Tag") { timerViewModel.quickTaskTag = "" }
                Divider()
                ForEach(Constants.defaultTags, id: \.self) { tag in
                    Button("#\(tag)") { timerViewModel.quickTaskTag = tag }
                }
            } label: {
                Text(timerViewModel.quickTaskTag.isEmpty ? "#Tag" : "#\(timerViewModel.quickTaskTag)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(timerViewModel.quickTaskTag.isEmpty ? AnyShapeStyle(.secondary) : AnyShapeStyle(activeAccent))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        timerViewModel.quickTaskTag.isEmpty ? Color.primary.opacity(0.06) : activeAccent.opacity(0.14),
                        in: Capsule()
                    )
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .focusCardSurface()
    }

    // MARK: - Bottom Action Dock

    private func openAppWindow(_ id: String) {
        if let onOpenWindow {
            onOpenWindow(id)
        } else {
            openWindow(id: id)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private var navigationDock: some View {
        HStack(spacing: 4) {
            MenuBarDockButton(title: "Stats", systemImage: "chart.bar", hint: "Opens the statistics window") {
                openAppWindow("stats")
            }
            .keyboardShortcut("1", modifiers: .command)

            MenuBarDockButton(title: "Badges", systemImage: "trophy", hint: "Opens the achievements window") {
                openAppWindow("achievements")
            }
            .keyboardShortcut("2", modifiers: .command)

            MenuBarDockButton(title: "Settings", systemImage: "gearshape", hint: "Opens the settings window") {
                openAppWindow("settings")
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()
                .frame(height: 22)
                .padding(.horizontal, 2)

            MenuBarDockButton(
                title: "Quit",
                systemImage: "power",
                hint: "Quits the application",
                isDestructive: true
            ) {
                NSApplication.shared.terminate(nil)
            }
            .frame(width: 48)
            .keyboardShortcut("q", modifiers: .command)
        }
    }
}

private struct DurationNudgeButton: View {
    let label: String
    let hint: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(isHovered ? .primary : .secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    Color.primary.opacity(isHovered ? 0.12 : 0.06),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityLabel(label)
        .accessibilityHint(hint)
    }
}

private struct ResetCircleButton: View {
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(role: .destructive, action: action) {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isHovered ? .red : .secondary)
                .frame(width: 36, height: 36)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .focusGlassCapsule(tint: isHovered ? .red : nil, interactive: true)
        .onHover { isHovered = $0 }
        .keyboardShortcut("r", modifiers: .command)
        .help("Reset timer")
        .accessibilityLabel("Reset timer")
        .accessibilityHint("Resets the current session to idle")
    }
}
