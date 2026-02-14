import SwiftUI

struct TimerDisplayView: View {
    let timerViewModel: TimerViewModel
    @AppStorage(UserDefaultsKeys.menuBarDisplayMode) private var displayMode = "timerText"

    var body: some View {
        switch displayMode {
        case "progressBar":
            progressBarLabel
                .accessibilityElement(children: .combine)
                .accessibilityLabel(timerAccessibilityLabel)
        case "icon":
            Image(systemName: iconName)
                .accessibilityLabel(timerAccessibilityLabel)
        default:
            Text(timerViewModel.menuBarTitle)
                .accessibilityLabel(timerAccessibilityLabel)
        }
    }

    private var timerAccessibilityLabel: String {
        switch timerViewModel.timerState {
        case .idle:
            return "FocusBar: idle"
        case .running:
            return "FocusBar: \(timerViewModel.currentSessionType.displayName), \(timerViewModel.formattedTime) remaining"
        case .paused:
            return "FocusBar: \(timerViewModel.currentSessionType.displayName) paused, \(timerViewModel.formattedTime) remaining"
        }
    }

    private var iconName: String {
        switch timerViewModel.timerState {
        case .idle: return "timer"
        case .running: return "timer.circle.fill"
        case .paused: return "pause.circle"
        }
    }

    private var progressBarLabel: some View {
        HStack(spacing: 2) {
            Image(systemName: iconName)
            if timerViewModel.timerState != .idle {
                ProgressView(value: progress)
                    .frame(width: 40)
            }
        }
    }

    private var progress: Double {
        guard timerViewModel.timerState != .idle else { return 0 }
        let durationKey: String
        switch timerViewModel.currentSessionType {
        case .pomodoro: durationKey = UserDefaultsKeys.pomodoroDuration
        case .shortBreak: durationKey = UserDefaultsKeys.shortBreakDuration
        case .longBreak: durationKey = UserDefaultsKeys.longBreakDuration
        }
        let totalMinutes = UserDefaults.standard.integer(forKey: durationKey)
        let totalSeconds = (totalMinutes > 0 ? totalMinutes : timerViewModel.currentSessionType.defaultDurationMinutes) * 60
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - (Double(timerViewModel.remainingSeconds) / Double(totalSeconds))
    }
}
