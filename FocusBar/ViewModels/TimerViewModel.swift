import Foundation
import SwiftUI
import SwiftData

@Observable
final class TimerViewModel {
    var timerService: TimerService
    var notificationService: NotificationService
    var gamificationViewModel: GamificationViewModel

    var timerState: TimerState { timerService.state }
    var remainingSeconds: Int { timerService.remainingSeconds }
    var currentSessionType: SessionType { timerService.currentSessionType }
    var completedPomodorosInCycle: Int { timerService.completedPomodorosInCycle }

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var menuBarTitle: String {
        if timerState == .idle {
            return "🍅"
        }
        let icon: String
        switch currentSessionType {
        case .pomodoro: icon = "🍅"
        case .shortBreak: icon = "☕"
        case .longBreak: icon = "🌿"
        }
        if timerState == .paused {
            return "\(icon) ⏸"
        }
        return "\(icon) \(formattedTime)"
    }

    var modelContext: ModelContext?
    private var dailyPomodoroCount: Int = 0

    init(
        timerService: TimerService = TimerService(),
        notificationService: NotificationService = NotificationService(),
        gamificationViewModel: GamificationViewModel = GamificationViewModel()
    ) {
        self.timerService = timerService
        self.notificationService = notificationService
        self.gamificationViewModel = gamificationViewModel
        setupCallbacks()
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

    func onLaunch() {
        gamificationViewModel.checkStreakOnLaunch()
        loadDailyPomodoroCount()
    }

    private func setupCallbacks() {
        timerService.onSessionComplete = { [weak self] sessionType, duration in
            guard let self else { return }

            if sessionType == .pomodoro {
                self.dailyPomodoroCount += 1
            }

            self.recordSession(type: sessionType, duration: duration, completed: true)

            if let ctx = self.modelContext {
                self.gamificationViewModel.processSessionComplete(
                    sessionType: sessionType,
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

            self.timerService.start()
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
            xpEarned: xp
        )
        session.endTime = Date()
        modelContext.insert(session)
        try? modelContext.save()
    }

    private func loadDailyPomodoroCount() {
        guard let modelContext else { return }
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let pomodoroType = SessionType.pomodoro.rawValue

        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.startTime >= today && $0.startTime < tomorrow && $0.completed == true && $0.type == pomodoroType }
        )
        dailyPomodoroCount = (try? modelContext.fetch(descriptor).count) ?? 0
    }
}
