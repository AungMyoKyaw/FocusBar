import Foundation
import SwiftUI
import SwiftData

@Observable
final class TimerViewModel {
    var timerService: TimerService
    var notificationService: NotificationService
    var gamificationViewModel: GamificationViewModel
    var remindersViewModel: RemindersViewModel

    var timerState: TimerState { timerService.state }
    var remainingSeconds: Int { timerService.remainingSeconds }
    var currentSessionType: SessionType { timerService.currentSessionType }
    var completedPomodorosInCycle: Int { timerService.completedPomodorosInCycle }

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var configuredDurationSeconds: Int {
        let durationKey: String
        switch currentSessionType {
        case .pomodoro: durationKey = UserDefaultsKeys.pomodoroDuration
        case .shortBreak: durationKey = UserDefaultsKeys.shortBreakDuration
        case .longBreak: durationKey = UserDefaultsKeys.longBreakDuration
        }
        let minutes = UserDefaults.standard.integer(forKey: durationKey)
        return (minutes > 0 ? minutes : currentSessionType.defaultDurationMinutes) * 60
    }

    var configuredDurationFormatted: String {
        let total = configuredDurationSeconds
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    var sessionProgress: Double {
        guard timerState != .idle else { return 0 }
        let total = configuredDurationSeconds
        guard total > 0 else { return 0 }
        let ratio = 1.0 - (Double(remainingSeconds) / Double(total))
        return min(max(ratio, 0), 1)
    }

    var menuBarSystemImage: String {
        switch timerState {
        case .idle:
            return "timer"
        case .paused:
            return "pause.circle"
        case .running:
            switch currentSessionType {
            case .pomodoro: return "timer"
            case .shortBreak: return "cup.and.saucer.fill"
            case .longBreak: return "leaf.fill"
            }
        }
    }

    var menuBarTitle: String {
        timerState == .idle ? "" : formattedTime
    }

    var modelContext: ModelContext?
    var currentError: AppError?
    var displayError: AppError? { currentError ?? remindersViewModel.currentError }
    private var dailyPomodoroCount: Int = 0

    init(
        timerService: TimerService = TimerService(),
        notificationService: NotificationService = NotificationService(),
        gamificationViewModel: GamificationViewModel = GamificationViewModel(),
        remindersViewModel: RemindersViewModel = RemindersViewModel()
    ) {
        self.timerService = timerService
        self.notificationService = notificationService
        self.gamificationViewModel = gamificationViewModel
        self.remindersViewModel = remindersViewModel
        setupCallbacks()
    }

    func clearError() {
        currentError = nil
        remindersViewModel.currentError = nil
    }

    func startFocus() {
        timerService.start()
    }

    func pause() {
        timerService.pause()
    }

    func togglePauseResume() {
        if timerState == .running {
            pause()
        } else if timerState == .paused {
            startFocus()
        }
    }

    func reset() {
        timerService.reset()
    }

    func skip() {
        timerService.skip()
    }

    func selectSessionType(_ type: SessionType) {
        timerService.selectSessionType(type)
    }

    func adjustConfiguredDuration(by deltaMinutes: Int) {
        guard timerState == .idle else { return }
        let durationKey: String
        let maxMinutes: Int
        switch currentSessionType {
        case .pomodoro:
            durationKey = UserDefaultsKeys.pomodoroDuration
            maxMinutes = 120
        case .shortBreak:
            durationKey = UserDefaultsKeys.shortBreakDuration
            maxMinutes = 60
        case .longBreak:
            durationKey = UserDefaultsKeys.longBreakDuration
            maxMinutes = 120
        }
        let stored = UserDefaults.standard.integer(forKey: durationKey)
        let current = stored > 0 ? stored : currentSessionType.defaultDurationMinutes
        let clamped = min(max(current + deltaMinutes, 1), maxMinutes)
        UserDefaults.standard.set(clamped, forKey: durationKey)
    }

    func onLaunch() {
        gamificationViewModel.checkStreakOnLaunch()
        loadDailyPomodoroCount()
    }

    private func setupCallbacks() {
        timerService.onSessionComplete = { [weak self] sessionType, duration in
            guard let self else { return }

            if sessionType == .pomodoro {
                self.dailyPomodoroCount += 1
                if self.remindersViewModel.selectedReminder != nil {
                    let minutes = max(1, duration / 60)
                    Task { await self.remindersViewModel.logFocusTime(minutes: minutes) }
                }
            }

            self.recordSession(type: sessionType, duration: duration, completed: true)

            if let ctx = self.modelContext {
                self.gamificationViewModel.processSessionComplete(
                    sessionType: sessionType,
                    durationSeconds: duration,
                    dailyPomodoros: self.dailyPomodoroCount,
                    modelContext: ctx,
                    notificationService: self.notificationService
                )
            }

            self.timerService.advanceToNextSession()
            let nextType = self.timerService.currentSessionType

            if UserDefaults.standard.bool(forKey: UserDefaultsKeys.bannerEnabled) {
                self.notificationService.sendSessionComplete(sessionType: sessionType, nextSessionType: nextType)
            }

            if UserDefaults.standard.bool(forKey: UserDefaultsKeys.autoStartNextSession) {
                self.timerService.start()
            }
        }
    }

    private func recordSession(type: SessionType, duration: Int, completed: Bool) {
        guard let modelContext else { return }
        let xp = completed ? gamificationViewModel.gamificationService.calculateXP(
            sessionType: type,
            streakDays: gamificationViewModel.streakService.currentStreak,
            level: gamificationViewModel.currentLevel,
            dailyGoalJustMet: false
        ).totalXP : 0

        let session = Session(
            startTime: Date().addingTimeInterval(-Double(duration)),
            duration: duration,
            type: type,
            completed: completed,
            reminderId: remindersViewModel.selectedReminder?.id,
            reminderTitle: remindersViewModel.selectedReminder?.title,
            xpEarned: xp
        )
        session.endTime = Date()
        modelContext.insert(session)
        do {
            try modelContext.save()
        } catch {
            let appError = AppError.dataError("Failed to save session: \(error.localizedDescription)")
            LoggingService.logError(appError, context: "recordSession")
            currentError = appError
        }
    }

    private func loadDailyPomodoroCount() {
        guard let modelContext else { return }
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today.addingTimeInterval(86_400)
        let pomodoroType = SessionType.pomodoro.rawValue

        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.startTime >= today && $0.startTime < tomorrow && $0.completed == true && $0.type == pomodoroType }
        )
        do {
            dailyPomodoroCount = try modelContext.fetch(descriptor).count
        } catch {
            LoggingService.logError(.dataError("Failed to load daily pomodoro count: \(error.localizedDescription)"), context: "loadDailyPomodoroCount")
            dailyPomodoroCount = 0
        }
    }
}
