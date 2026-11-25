import SwiftUI

struct TimerDisplayView: View {
    let timerViewModel: TimerViewModel
    @AppStorage(UserDefaultsKeys.menuBarDisplayMode) private var displayMode = MenuBarDisplayMode.timerText.rawValue

    var body: some View {
        switch displayMode {
        case MenuBarDisplayMode.progressBar.rawValue:
            progressBarLabel
                .accessibilityElement(children: .combine)
                .accessibilityLabel(timerAccessibilityLabel)
        case MenuBarDisplayMode.icon.rawValue:
            Image(systemName: timerViewModel.menuBarSystemImage)
                .accessibilityLabel(iconOnlyAccessibilityLabel)
        default:
            HStack(spacing: 4) {
                Image(systemName: timerViewModel.menuBarSystemImage)
                if !timerViewModel.menuBarTitle.isEmpty {
                    Text(timerViewModel.menuBarTitle)
                        .monospacedDigit()
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(timerAccessibilityLabel)
        }
    }

    private var iconOnlyAccessibilityLabel: String {
        switch timerViewModel.timerState {
        case .idle:
            return "FocusBar: idle"
        case .running:
            return "FocusBar: \(timerViewModel.currentSessionType.displayName) running"
        case .paused:
            return "FocusBar: \(timerViewModel.currentSessionType.displayName) paused"
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

    private var progressBarLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: timerViewModel.menuBarSystemImage)
            if timerViewModel.timerState != .idle {
                ProgressView(value: timerViewModel.sessionProgress)
                    .frame(width: 40)
            }
        }
    }
}
