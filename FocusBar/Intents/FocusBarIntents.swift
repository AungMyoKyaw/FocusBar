import Foundation
import AppIntents

@MainActor
final class FocusBarCommandBridge {
    static let shared = FocusBarCommandBridge()
    weak var timerViewModel: TimerViewModel?

    private init() {}
}

struct StartFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Focus Session"
    static var description = IntentDescription("Starts a FocusBar Pomodoro focus session, optionally with a custom duration and task name.")

    @Parameter(title: "Duration (Minutes)")
    var durationMinutes: Int?

    @Parameter(title: "Task")
    var task: String?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let vm = FocusBarCommandBridge.shared.timerViewModel else {
            return .result(dialog: "FocusBar is not ready yet.")
        }
        if let task, !task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            vm.quickTaskTitle = task.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if vm.timerState == .idle {
            vm.selectSessionType(.pomodoro)
            vm.timerService.start(duration: durationMinutes)
        } else if vm.timerState == .paused {
            vm.startFocus()
        }
        return .result(dialog: "FocusBar timer started (\(vm.formattedTime)).")
    }
}

struct PauseResumeFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause or Resume Focus"
    static var description = IntentDescription("Toggles pause/resume on the active FocusBar session.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let vm = FocusBarCommandBridge.shared.timerViewModel else {
            return .result(dialog: "FocusBar is not ready yet.")
        }
        if vm.timerState == .idle {
            vm.startFocus()
            return .result(dialog: "Started FocusBar session.")
        }
        vm.togglePauseResume()
        let stateLabel = vm.timerState == .paused ? "Paused" : "Resumed"
        return .result(dialog: "\(stateLabel) FocusBar at \(vm.formattedTime).")
    }
}

struct SkipSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Skip Current Session"
    static var description = IntentDescription("Skips the current FocusBar session and advances to the next phase.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let vm = FocusBarCommandBridge.shared.timerViewModel else {
            return .result(dialog: "FocusBar is not ready yet.")
        }
        vm.skip()
        return .result(dialog: "Skipped to \(vm.currentSessionType.displayName).")
    }
}

struct ResetTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Reset FocusBar Timer"
    static var description = IntentDescription("Resets the current FocusBar timer back to idle.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let vm = FocusBarCommandBridge.shared.timerViewModel else {
            return .result(dialog: "FocusBar is not ready yet.")
        }
        vm.reset()
        return .result(dialog: "FocusBar timer reset.")
    }
}

struct GetFocusStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Get FocusBar Status"
    static var description = IntentDescription("Returns the current FocusBar session state and remaining time.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        guard let vm = FocusBarCommandBridge.shared.timerViewModel else {
            return .result(value: "Unavailable", dialog: "FocusBar is not running.")
        }
        let status: String
        switch vm.timerState {
        case .idle:
            status = "Idle (\(vm.currentSessionType.displayName) ready: \(vm.configuredDurationFormatted))"
        case .running:
            status = "Running \(vm.currentSessionType.displayName): \(vm.formattedTime)"
        case .paused:
            status = "Paused \(vm.currentSessionType.displayName): \(vm.formattedTime)"
        }
        return .result(value: status, dialog: "\(status)")
    }
}

struct FocusBarShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartFocusIntent(),
            phrases: ["Start focus in \(.applicationName)", "Start Pomodoro in \(.applicationName)"],
            shortTitle: "Start Focus",
            systemImageName: "timer"
        )
        AppShortcut(
            intent: PauseResumeFocusIntent(),
            phrases: ["Pause or resume \(.applicationName)"],
            shortTitle: "Pause / Resume",
            systemImageName: "pause.circle"
        )
        AppShortcut(
            intent: SkipSessionIntent(),
            phrases: ["Skip session in \(.applicationName)"],
            shortTitle: "Skip Session",
            systemImageName: "forward.end"
        )
        AppShortcut(
            intent: GetFocusStatusIntent(),
            phrases: ["Check \(.applicationName) status"],
            shortTitle: "Focus Status",
            systemImageName: "clock"
        )
    }
}
