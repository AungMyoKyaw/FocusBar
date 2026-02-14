import Foundation
import AppKit

enum TimerState {
    case idle
    case running
    case paused
}

@Observable
final class TimerService {
    var state: TimerState = .idle
    var remainingSeconds: Int = 0
    var currentSessionType: SessionType = .pomodoro
    var completedPomodorosInCycle: Int = 0

    var onSessionComplete: ((SessionType, Int) -> Void)?
    var onTick: ((Int) -> Void)?

    private var sessionStartDate: Date?
    private var pausedRemainingSeconds: Int = 0
    private var timer: Timer?
    private var totalDurationSeconds: Int = 0

    private var lastStateChangeDate: Date = .distantPast
    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?

    init() {
        setupSleepWakeObservers()
    }

    deinit {
        timer?.invalidate()
        if let sleepObserver { NotificationCenter.default.removeObserver(sleepObserver) }
        if let wakeObserver { NotificationCenter.default.removeObserver(wakeObserver) }
    }

    func start(duration: Int? = nil) {
        guard Date().timeIntervalSince(lastStateChangeDate) >= 0.3 else {
            LoggingService.logDebug("Rapid input ignored for start", category: .timer)
            return
        }
        lastStateChangeDate = Date()

        switch state {
        case .idle:
            let durationMinutes = duration ?? durationForCurrentType()
            totalDurationSeconds = durationMinutes * 60
            remainingSeconds = totalDurationSeconds
            sessionStartDate = Date()
            state = .running
            LoggingService.logInfo("Timer started for \(currentSessionType) (\(durationMinutes) min)", category: .timer)
            startTimer()

        case .paused:
            let elapsed = totalDurationSeconds - pausedRemainingSeconds
            sessionStartDate = Date().addingTimeInterval(-Double(elapsed))
            state = .running
            LoggingService.logInfo("Timer resumed for \(currentSessionType)", category: .timer)
            startTimer()

        case .running:
            break
        }
    }

    func pause() {
        guard state == .running else { return }
        guard Date().timeIntervalSince(lastStateChangeDate) >= 0.3 else {
            LoggingService.logDebug("Rapid input ignored for pause", category: .timer)
            return
        }
        lastStateChangeDate = Date()
        pausedRemainingSeconds = remainingSeconds
        state = .paused
        LoggingService.logInfo("Timer paused for \(currentSessionType)", category: .timer)
        stopTimer()
    }

    func reset() {
        guard Date().timeIntervalSince(lastStateChangeDate) >= 0.3 else {
            LoggingService.logDebug("Rapid input ignored for reset", category: .timer)
            return
        }
        lastStateChangeDate = Date()
        LoggingService.logInfo("Timer reset for \(currentSessionType)", category: .timer)
        stopTimer()
        state = .idle
        remainingSeconds = 0
        sessionStartDate = nil
        totalDurationSeconds = 0
    }

    func skip() {
        let completedType = currentSessionType
        let completedDuration = totalDurationSeconds
        LoggingService.logInfo("Timer skipped for \(completedType)", category: .timer)
        stopTimer()
        state = .idle
        remainingSeconds = 0
        sessionStartDate = nil
        onSessionComplete?(completedType, completedDuration)
    }

    private func durationForCurrentType() -> Int {
        let defaults = UserDefaults.standard
        switch currentSessionType {
        case .pomodoro:
            let val = defaults.integer(forKey: UserDefaultsKeys.pomodoroDuration)
            return val > 0 ? val : Constants.defaultPomodoroDuration
        case .shortBreak:
            let val = defaults.integer(forKey: UserDefaultsKeys.shortBreakDuration)
            return val > 0 ? val : Constants.defaultShortBreakDuration
        case .longBreak:
            let val = defaults.integer(forKey: UserDefaultsKeys.longBreakDuration)
            return val > 0 ? val : Constants.defaultLongBreakDuration
        }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard state == .running, let startDate = sessionStartDate else { return }

        let elapsed = Int(Date().timeIntervalSince(startDate))
        remainingSeconds = max(0, totalDurationSeconds - elapsed)
        onTick?(remainingSeconds)

        if remainingSeconds <= 0 {
            let completedType = currentSessionType
            let completedDuration = totalDurationSeconds
            LoggingService.logInfo("Session complete: \(completedType) (\(completedDuration)s)", category: .timer)
            stopTimer()
            state = .idle
            remainingSeconds = 0
            sessionStartDate = nil
            onSessionComplete?(completedType, completedDuration)
        }
    }

    private func setupSleepWakeObservers() {
        sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, self.state == .running else { return }
            self.pausedRemainingSeconds = self.remainingSeconds
        }

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, self.state == .running, let startDate = self.sessionStartDate else { return }
            let elapsed = Int(Date().timeIntervalSince(startDate))
            self.remainingSeconds = max(0, self.totalDurationSeconds - elapsed)
            if self.remainingSeconds <= 0 {
                self.tick()
            }
        }
    }

    func advanceToNextSession() {
        LoggingService.logDebug("Advancing from \(currentSessionType), cycle: \(completedPomodorosInCycle)", category: .timer)
        let sessionsUntilLong = UserDefaults.standard.integer(forKey: UserDefaultsKeys.sessionsUntilLongBreak)
        let maxSessions = sessionsUntilLong > 0 ? sessionsUntilLong : Constants.defaultSessionsUntilLongBreak

        switch currentSessionType {
        case .pomodoro:
            completedPomodorosInCycle += 1
            if completedPomodorosInCycle >= maxSessions {
                currentSessionType = .longBreak
            } else {
                currentSessionType = .shortBreak
            }
        case .shortBreak, .longBreak:
            if currentSessionType == .longBreak {
                completedPomodorosInCycle = 0
            }
            currentSessionType = .pomodoro
        }
    }
}
