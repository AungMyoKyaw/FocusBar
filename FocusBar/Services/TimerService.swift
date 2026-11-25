import Foundation
import AppKit

nonisolated enum TimerState: Equatable, Sendable {
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
    var isOvertime: Bool = false
    var overtimeSeconds: Int = 0
    private(set) var totalDurationSeconds: Int = 0

    var onSessionComplete: ((SessionType, Int) -> Void)?
    var onOvertimeStart: ((SessionType) -> Void)?
    var onTick: ((Int) -> Void)?

    private var sessionStartDate: Date?
    private var pausedRemainingSeconds: Int = 0
    private var timer: Timer?

    private let defaults: UserDefaults
    private let debounceInterval: TimeInterval
    private var lastStateChangeDate: Date = .distantPast
    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?

    init(defaults: UserDefaults = .standard, debounceInterval: TimeInterval = 0.3) {
        self.defaults = defaults
        self.debounceInterval = debounceInterval
        setupSleepWakeObservers()
    }

    deinit {
        timer?.invalidate()
        if let sleepObserver { NSWorkspace.shared.notificationCenter.removeObserver(sleepObserver) }
        if let wakeObserver { NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver) }
    }

    var estimatedEndDate: Date? {
        guard state == .running, !isOvertime else { return nil }
        if let sessionStartDate {
            return sessionStartDate.addingTimeInterval(TimeInterval(totalDurationSeconds))
        }
        return Date().addingTimeInterval(TimeInterval(remainingSeconds))
    }

    func start(duration: Int? = nil) {
        guard Date().timeIntervalSince(lastStateChangeDate) >= debounceInterval else {
            LoggingService.logDebug("Rapid input ignored for start", category: .timer)
            return
        }
        lastStateChangeDate = Date()

        switch state {
        case .idle:
            let durationMinutes = duration ?? durationForCurrentType()
            totalDurationSeconds = max(1, durationMinutes) * 60
            remainingSeconds = totalDurationSeconds
            isOvertime = false
            overtimeSeconds = 0
            sessionStartDate = Date()
            state = .running
            LoggingService.logInfo("Timer started for \(currentSessionType) (\(durationMinutes) min)", category: .timer)
            startTimer()

        case .paused:
            if isOvertime {
                sessionStartDate = Date().addingTimeInterval(-Double(totalDurationSeconds + overtimeSeconds))
            } else {
                let elapsed = totalDurationSeconds - pausedRemainingSeconds
                sessionStartDate = Date().addingTimeInterval(-Double(elapsed))
            }
            state = .running
            LoggingService.logInfo("Timer resumed for \(currentSessionType)", category: .timer)
            startTimer()

        case .running:
            break
        }
    }

    func pause() {
        guard state == .running else { return }
        guard Date().timeIntervalSince(lastStateChangeDate) >= debounceInterval else {
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
        guard Date().timeIntervalSince(lastStateChangeDate) >= debounceInterval else {
            LoggingService.logDebug("Rapid input ignored for reset", category: .timer)
            return
        }
        lastStateChangeDate = Date()
        LoggingService.logInfo("Timer reset for \(currentSessionType)", category: .timer)
        stopTimer()
        state = .idle
        remainingSeconds = 0
        isOvertime = false
        overtimeSeconds = 0
        sessionStartDate = nil
        totalDurationSeconds = 0
    }

    func skip() {
        let skippedType = currentSessionType
        LoggingService.logInfo("Timer skipped for \(skippedType)", category: .timer)
        stopTimer()
        state = .idle
        remainingSeconds = 0
        isOvertime = false
        overtimeSeconds = 0
        sessionStartDate = nil
        totalDurationSeconds = 0
        advanceToNextSession()
    }

    func extendActiveSession(by deltaMinutes: Int) {
        guard state != .idle, !isOvertime else { return }
        let deltaSeconds = deltaMinutes * 60
        let newTotal = min(max(totalDurationSeconds + deltaSeconds, 60), 10_800)
        let appliedDelta = newTotal - totalDurationSeconds
        guard appliedDelta != 0 else { return }

        totalDurationSeconds = newTotal
        if state == .running {
            remainingSeconds = max(1, remainingSeconds + appliedDelta)
        } else if state == .paused {
            pausedRemainingSeconds = max(1, pausedRemainingSeconds + appliedDelta)
            remainingSeconds = pausedRemainingSeconds
        }
        LoggingService.logInfo("Extended active session by \(appliedDelta / 60)m (total: \(totalDurationSeconds / 60)m)", category: .timer)
    }

    func trimElapsedSeconds(_ seconds: Int) {
        guard state != .idle, seconds > 0 else { return }
        if isOvertime {
            overtimeSeconds = max(0, overtimeSeconds - seconds)
            if let startDate = sessionStartDate {
                sessionStartDate = startDate.addingTimeInterval(TimeInterval(seconds))
            }
            return
        }
        if state == .running, let startDate = sessionStartDate {
            let newStart = min(Date(), startDate.addingTimeInterval(TimeInterval(seconds)))
            sessionStartDate = newStart
            let elapsed = Int(Date().timeIntervalSince(newStart))
            remainingSeconds = max(0, totalDurationSeconds - elapsed)
        } else if state == .paused {
            pausedRemainingSeconds = min(totalDurationSeconds, pausedRemainingSeconds + seconds)
            remainingSeconds = pausedRemainingSeconds
        }
    }

    func completeOvertimeSession() {
        guard isOvertime else { return }
        let completedDuration = totalDurationSeconds + overtimeSeconds
        let completedType = currentSessionType
        LoggingService.logInfo("Overtime session completed: \(completedType) (\(completedDuration)s)", category: .timer)
        stopTimer()
        state = .idle
        remainingSeconds = 0
        isOvertime = false
        overtimeSeconds = 0
        sessionStartDate = nil
        totalDurationSeconds = 0
        onSessionComplete?(completedType, completedDuration)
    }

    func selectSessionType(_ type: SessionType) {
        guard state == .idle else { return }
        currentSessionType = type
    }

    private func durationForCurrentType() -> Int {
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

    func tick() {
        guard state == .running, let startDate = sessionStartDate else { return }

        let elapsed = Int(Date().timeIntervalSince(startDate))
        let remaining = totalDurationSeconds - elapsed

        if remaining > 0 {
            remainingSeconds = remaining
            onTick?(remainingSeconds)
            return
        }

        if currentSessionType == .pomodoro, defaults.bool(forKey: UserDefaultsKeys.overtimeEnabled) {
            let wasOvertime = isOvertime
            isOvertime = true
            remainingSeconds = 0
            overtimeSeconds = max(0, -remaining)
            if !wasOvertime {
                LoggingService.logInfo("Entering overtime mode", category: .timer)
                onOvertimeStart?(currentSessionType)
            }
            onTick?(0)
            return
        }

        let completedType = currentSessionType
        let completedDuration = totalDurationSeconds
        LoggingService.logInfo("Session complete: \(completedType) (\(completedDuration)s)", category: .timer)
        stopTimer()
        state = .idle
        remainingSeconds = 0
        isOvertime = false
        overtimeSeconds = 0
        sessionStartDate = nil
        totalDurationSeconds = 0
        onSessionComplete?(completedType, completedDuration)
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
            guard let self, self.state == .running else { return }
            self.tick()
        }
    }

    func advanceToNextSession() {
        LoggingService.logDebug("Advancing from \(currentSessionType), cycle: \(completedPomodorosInCycle)", category: .timer)
        let sessionsUntilLong = defaults.integer(forKey: UserDefaultsKeys.sessionsUntilLongBreak)
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
