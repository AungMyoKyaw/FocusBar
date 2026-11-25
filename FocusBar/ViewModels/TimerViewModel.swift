import Foundation
import SwiftUI
import SwiftData

@Observable
final class TimerViewModel {
    var timerService: TimerService
    var notificationService: NotificationService
    var gamificationViewModel: GamificationViewModel
    var remindersViewModel: RemindersViewModel
    let soundService: SoundService
    let hotkeyService: GlobalHotkeyService
    let calendarService: CalendarService
    let idleMonitorService: IdleMonitorService
    let distractionGuardService: DistractionGuardService
    let floatingPanelController = FloatingTimerPanelController()
    let breakOverlayController = BreakOverlayController()

    var timerState: TimerState { timerService.state }
    var remainingSeconds: Int { timerService.remainingSeconds }
    var currentSessionType: SessionType { timerService.currentSessionType }
    var completedPomodorosInCycle: Int { timerService.completedPomodorosInCycle }
    var isOvertime: Bool { timerService.isOvertime }
    var overtimeSeconds: Int { timerService.overtimeSeconds }

    var quickTaskTitle: String {
        didSet { UserDefaults.standard.set(quickTaskTitle, forKey: UserDefaultsKeys.quickTaskTitle) }
    }

    var quickTaskTag: String {
        didSet { UserDefaults.standard.set(quickTaskTag, forKey: UserDefaultsKeys.quickTaskTag) }
    }

    var ambientSoundMode: AmbientSoundMode {
        didSet {
            UserDefaults.standard.set(ambientSoundMode.rawValue, forKey: UserDefaultsKeys.ambientSoundMode)
            syncAmbientAudio()
        }
    }

    var isFloatingTimerVisible: Bool = false
    var floatingWidgetSize: FloatingWidgetSize {
        didSet { floatingPanelController.setSize(floatingWidgetSize) }
    }
    var pendingIdleTrimSeconds: Int?
    var completedReminderPrompt: ReminderItem?

    var formattedTime: String {
        if isOvertime {
            let minutes = overtimeSeconds / 60
            let seconds = overtimeSeconds % 60
            return String(format: "+%02d:%02d", minutes, seconds)
        }
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
        if isOvertime { return 1 }
        let total = max(timerService.totalDurationSeconds, configuredDurationSeconds)
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

    private static let endTimeFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt
    }()

    var menuBarTitle: String {
        guard timerState != .idle else { return "" }
        if UserDefaults.standard.bool(forKey: UserDefaultsKeys.showEndTimeInMenuBar),
           let endDate = timerService.estimatedEndDate {
            return "\(formattedTime) · \(Self.endTimeFormatter.string(from: endDate))"
        }
        return formattedTime
    }

    var modelContext: ModelContext?
    var currentError: AppError?
    var displayError: AppError? { currentError ?? remindersViewModel.currentError }
    private var dailyPomodoroCount: Int = 0

    init(
        timerService: TimerService = TimerService(),
        notificationService: NotificationService = NotificationService(),
        gamificationViewModel: GamificationViewModel = GamificationViewModel(),
        remindersViewModel: RemindersViewModel = RemindersViewModel(),
        soundService: SoundService = SoundService(),
        hotkeyService: GlobalHotkeyService = GlobalHotkeyService(),
        calendarService: CalendarService = CalendarService(),
        idleMonitorService: IdleMonitorService = IdleMonitorService(),
        distractionGuardService: DistractionGuardService = DistractionGuardService()
    ) {
        self.timerService = timerService
        self.notificationService = notificationService
        self.gamificationViewModel = gamificationViewModel
        self.remindersViewModel = remindersViewModel
        self.soundService = soundService
        self.hotkeyService = hotkeyService
        self.calendarService = calendarService
        self.idleMonitorService = idleMonitorService
        self.distractionGuardService = distractionGuardService
        self.quickTaskTitle = UserDefaults.standard.string(forKey: UserDefaultsKeys.quickTaskTitle) ?? ""
        self.quickTaskTag = UserDefaults.standard.string(forKey: UserDefaultsKeys.quickTaskTag) ?? ""
        let rawAmbient = UserDefaults.standard.string(forKey: UserDefaultsKeys.ambientSoundMode) ?? AmbientSoundMode.off.rawValue
        self.ambientSoundMode = AmbientSoundMode(rawValue: rawAmbient) ?? .off
        self.floatingWidgetSize = floatingPanelController.size
        setupCallbacks()
    }

    func clearError() {
        currentError = nil
        remindersViewModel.currentError = nil
    }

    func startFocus() {
        pendingIdleTrimSeconds = nil
        timerService.start()
        syncActiveMonitors()
    }

    func pause() {
        timerService.pause()
        syncActiveMonitors()
    }

    func togglePauseResume() {
        if timerState == .running {
            pause()
        } else if timerState == .paused {
            startFocus()
        } else {
            startFocus()
        }
    }

    func reset() {
        pendingIdleTrimSeconds = nil
        timerService.reset()
        breakOverlayController.dismiss()
        syncActiveMonitors()
    }

    func skip() {
        pendingIdleTrimSeconds = nil
        timerService.skip()
        breakOverlayController.dismiss()
        syncActiveMonitors()
    }

    func selectSessionType(_ type: SessionType) {
        timerService.selectSessionType(type)
    }

    func extendActiveSession(by deltaMinutes: Int) {
        timerService.extendActiveSession(by: deltaMinutes)
    }

    func completeOvertimeSession() {
        timerService.completeOvertimeSession()
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

    func toggleFloatingTimer() {
        floatingPanelController.toggle(viewModel: self)
        isFloatingTimerVisible = floatingPanelController.isVisible
    }

    func cycleFloatingWidgetSize() {
        floatingPanelController.cycleSize()
        floatingWidgetSize = floatingPanelController.size
    }

    func cycleAmbientSound() {
        let all = AmbientSoundMode.allCases
        if let idx = all.firstIndex(of: ambientSoundMode) {
            ambientSoundMode = all[(idx + 1) % all.count]
        }
    }

    func trimIdleTime() {
        if let seconds = pendingIdleTrimSeconds {
            timerService.trimElapsedSeconds(seconds)
        }
        pendingIdleTrimSeconds = nil
    }

    func dismissIdlePrompt() {
        pendingIdleTrimSeconds = nil
    }

    func completeLinkedReminder() {
        Task {
            await remindersViewModel.completeSelectedReminder()
            await MainActor.run {
                completedReminderPrompt = nil
            }
        }
    }

    func dismissReminderPrompt() {
        completedReminderPrompt = nil
    }

    func refreshHotkeysFromDefaults() {
        let enabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.globalHotkeysEnabled)
        hotkeyService.setEnabled(enabled)
    }

    func onLaunch() {
        gamificationViewModel.checkStreakOnLaunch()
        loadDailyPomodoroCount()
        refreshHotkeysFromDefaults()
    }

    private func setupCallbacks() {
        hotkeyService.onStartPause = { [weak self] in
            guard let self else { return }
            if self.isOvertime {
                self.completeOvertimeSession()
            } else {
                self.togglePauseResume()
            }
        }
        hotkeyService.onReset = { [weak self] in
            self?.reset()
        }
        hotkeyService.onSkip = { [weak self] in
            self?.skip()
        }

        idleMonitorService.onReturnFromIdle = { [weak self] awaySeconds in
            guard let self, self.timerState == .running, self.currentSessionType == .pomodoro else { return }
            self.pendingIdleTrimSeconds = awaySeconds
        }

        distractionGuardService.onDistractingAppActivated = { [weak self] appName in
            guard let self, self.timerState == .running, self.currentSessionType == .pomodoro else { return }
            let task = self.resolvedSessionTitle
            self.notificationService.sendFocusGuardNudge(appName: appName, taskTitle: task)
        }

        timerService.onOvertimeStart = { [weak self] sessionType in
            guard let self else { return }
            self.playCompletionChime(for: sessionType)
        }

        timerService.onSessionComplete = { [weak self] sessionType, duration in
            guard let self else { return }

            let linkedReminder = self.remindersViewModel.selectedReminder
            let endDate = Date()
            let startDate = endDate.addingTimeInterval(-Double(duration))

            if sessionType == .pomodoro {
                self.dailyPomodoroCount += 1
                if let linkedReminder {
                    let minutes = max(1, duration / 60)
                    Task { await self.remindersViewModel.logFocusTime(minutes: minutes) }
                    self.completedReminderPrompt = linkedReminder
                }

                if UserDefaults.standard.bool(forKey: UserDefaultsKeys.calendarSyncEnabled) {
                    let calendarName = UserDefaults.standard.string(forKey: UserDefaultsKeys.calendarName) ?? Constants.defaultCalendarName
                    let eventTitle = "FocusBar: \(self.resolvedSessionTitle ?? "Focus Session")"
                    let notes = self.quickTaskTag.isEmpty ? nil : "#\(self.quickTaskTag)"
                    Task {
                        await self.calendarService.logCompletedSession(
                            title: eventTitle,
                            startDate: startDate,
                            endDate: endDate,
                            notes: notes,
                            calendarName: calendarName
                        )
                    }
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

            self.playCompletionChime(for: sessionType)

            self.timerService.advanceToNextSession()
            let nextType = self.timerService.currentSessionType

            self.notificationService.sendSessionComplete(
                sessionType: sessionType,
                nextSessionType: nextType,
                includeSystemSound: false
            )

            let shouldAutoStart: Bool
            if nextType == .pomodoro {
                shouldAutoStart = UserDefaults.standard.bool(forKey: UserDefaultsKeys.autoStartFocus)
                    || UserDefaults.standard.bool(forKey: UserDefaultsKeys.autoStartNextSession)
            } else {
                shouldAutoStart = UserDefaults.standard.bool(forKey: UserDefaultsKeys.autoStartBreaks)
                    || UserDefaults.standard.bool(forKey: UserDefaultsKeys.autoStartNextSession)
            }

            if shouldAutoStart {
                self.timerService.start()
                if nextType != .pomodoro,
                   UserDefaults.standard.bool(forKey: UserDefaultsKeys.breakOverlayEnabled) {
                    self.breakOverlayController.show(viewModel: self)
                }
            }

            self.syncActiveMonitors()
        }
    }

    private var resolvedSessionTitle: String? {
        let trimmed = quickTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        return remindersViewModel.selectedReminder?.title
    }

    private func playCompletionChime(for sessionType: SessionType) {
        guard UserDefaults.standard.bool(forKey: UserDefaultsKeys.soundEnabled) else { return }
        let key = sessionType == .pomodoro ? UserDefaultsKeys.focusEndSound : UserDefaultsKeys.breakEndSound
        let rawSound = UserDefaults.standard.string(forKey: key) ?? ChimeSound.glass.rawValue
        let sound = ChimeSound(rawValue: rawSound) ?? .glass
        let storedVol = UserDefaults.standard.object(forKey: UserDefaultsKeys.soundVolume) as? Double ?? 0.75
        soundService.playChime(sound, volume: Float(storedVol))
    }

    private func syncActiveMonitors() {
        syncAmbientAudio()

        let isRunningFocus = timerState == .running && currentSessionType == .pomodoro
        if isRunningFocus && UserDefaults.standard.bool(forKey: UserDefaultsKeys.idleDetectionEnabled) {
            let threshold = UserDefaults.standard.integer(forKey: UserDefaultsKeys.idleThresholdMinutes)
            idleMonitorService.startMonitoring(thresholdMinutes: threshold > 0 ? threshold : Constants.defaultIdleThresholdMinutes)
        } else {
            idleMonitorService.stopMonitoring()
        }

        if isRunningFocus && UserDefaults.standard.bool(forKey: UserDefaultsKeys.distractionGuardEnabled) {
            let rawIDs = UserDefaults.standard.string(forKey: UserDefaultsKeys.blockedBundleIDs) ?? ""
            let ids = rawIDs.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            distractionGuardService.startMonitoring(blockedBundleIDs: ids)
        } else {
            distractionGuardService.stopMonitoring()
        }
    }

    private func syncAmbientAudio() {
        let isRunningFocus = timerState == .running && currentSessionType == .pomodoro
        if isRunningFocus && ambientSoundMode != .off {
            let vol = UserDefaults.standard.object(forKey: UserDefaultsKeys.ambientVolume) as? Double ?? 0.35
            soundService.startAmbient(mode: ambientSoundMode, volume: Float(vol))
        } else {
            soundService.stopAmbient()
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

        let trimmedTask = quickTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTag = quickTaskTag.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseSeconds = timerService.totalDurationSeconds > 0 ? timerService.totalDurationSeconds : duration
        let overtime = max(0, duration - baseSeconds)

        let session = Session(
            startTime: Date().addingTimeInterval(-Double(duration)),
            duration: duration,
            type: type,
            completed: completed,
            reminderId: remindersViewModel.selectedReminder?.id,
            reminderTitle: remindersViewModel.selectedReminder?.title,
            xpEarned: xp,
            taskTitle: trimmedTask.isEmpty ? nil : trimmedTask,
            tag: trimmedTag.isEmpty ? nil : trimmedTag,
            notes: nil,
            overtimeSeconds: overtime
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
