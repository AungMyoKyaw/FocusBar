import SwiftUI
import SwiftData
import AppKit

@MainActor
final class FocusBarAppDelegate: NSObject, NSApplicationDelegate {
    private var sharedModelContainer: ModelContainer!
    private var timerViewModel: TimerViewModel!
    private var statusBarController: StatusBarController?
    private var managedWindows: [String: NSWindow] = [:]

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: [
            UserDefaultsKeys.pomodoroDuration: Constants.defaultPomodoroDuration,
            UserDefaultsKeys.shortBreakDuration: Constants.defaultShortBreakDuration,
            UserDefaultsKeys.longBreakDuration: Constants.defaultLongBreakDuration,
            UserDefaultsKeys.sessionsUntilLongBreak: Constants.defaultSessionsUntilLongBreak,
            UserDefaultsKeys.dailyGoal: Constants.defaultDailyGoal,
            UserDefaultsKeys.bannerEnabled: true,
            UserDefaultsKeys.soundEnabled: true,
            UserDefaultsKeys.focusEndSound: ChimeSound.glass.rawValue,
            UserDefaultsKeys.breakEndSound: ChimeSound.ping.rawValue,
            UserDefaultsKeys.soundVolume: 0.75,
            UserDefaultsKeys.ambientSoundMode: AmbientSoundMode.off.rawValue,
            UserDefaultsKeys.ambientVolume: 0.35,
            UserDefaultsKeys.autoStartNextSession: false,
            UserDefaultsKeys.autoStartBreaks: false,
            UserDefaultsKeys.autoStartFocus: false,
            UserDefaultsKeys.overtimeEnabled: false,
            UserDefaultsKeys.breakOverlayEnabled: false,
            UserDefaultsKeys.globalHotkeysEnabled: true,
            UserDefaultsKeys.calendarSyncEnabled: false,
            UserDefaultsKeys.calendarName: Constants.defaultCalendarName,
            UserDefaultsKeys.idleDetectionEnabled: false,
            UserDefaultsKeys.idleThresholdMinutes: Constants.defaultIdleThresholdMinutes,
            UserDefaultsKeys.distractionGuardEnabled: false,
            UserDefaultsKeys.blockedBundleIDs: "",
            UserDefaultsKeys.showEndTimeInMenuBar: false,
            UserDefaultsKeys.menuBarDisplayMode: MenuBarDisplayMode.timerText.rawValue,
        ])

        let schema = Schema([
            Session.self,
            DailyStats.self,
            Achievement.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            LoggingService.logError(.dataError("ModelContainer creation failed: \(error.localizedDescription)"), context: "App initialization")
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: schema, configurations: [fallbackConfig])
        }
        self.sharedModelContainer = container

        let vm = TimerViewModel()
        vm.modelContext = container.mainContext
        vm.onLaunch()
        FocusBarCommandBridge.shared.timerViewModel = vm
        self.timerViewModel = vm

        self.statusBarController = StatusBarController(
            timerViewModel: vm,
            modelContainer: container,
            onOpenWindow: { [weak self] id in
                self?.openWindow(id: id)
            }
        )

        if !UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasCompletedOnboarding) {
            openWindow(id: "onboarding")
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            handleURL(url)
        }
    }

    func openWindow(id: String) {
        statusBarController?.closePopover()

        if let existing = managedWindows[id] {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window: NSWindow
        switch id {
        case "onboarding":
            let controller = NSHostingController(
                rootView: OnboardingContainerView(onDismiss: { [weak self] in
                    self?.managedWindows["onboarding"]?.close()
                })
            )
            window = NSWindow(contentViewController: controller)
            window.title = "Welcome to FocusBar"
            window.styleMask = [.titled, .closable]
            window.setContentSize(NSSize(width: 480, height: 560))

        case "settings":
            let controller = NSHostingController(
                rootView: SettingsView(timerViewModel: timerViewModel)
                    .modelContainer(sharedModelContainer)
            )
            window = NSWindow(contentViewController: controller)
            window.title = "Settings"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.setContentSize(NSSize(width: 560, height: 480))

        case "stats":
            let controller = NSHostingController(
                rootView: StatsView()
                    .modelContainer(sharedModelContainer)
            )
            window = NSWindow(contentViewController: controller)
            window.title = "Statistics"
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.setContentSize(NSSize(width: 760, height: 640))

        case "achievements":
            let controller = NSHostingController(
                rootView: AchievementsView()
                    .modelContainer(sharedModelContainer)
            )
            window = NSWindow(contentViewController: controller)
            window.title = "Achievements"
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.setContentSize(NSSize(width: 660, height: 580))

        default:
            return
        }

        window.center()
        window.isReleasedWhenClosed = false
        managedWindows[id] = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func handleURL(_ url: URL) {
        guard url.scheme?.lowercased() == "focusbar" else { return }
        let action = (url.host ?? url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))).lowercased()
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []

        switch action {
        case "start":
            if let task = queryItems.first(where: { $0.name == "task" })?.value {
                timerViewModel.quickTaskTitle = task
            }
            if let minsStr = queryItems.first(where: { $0.name == "minutes" })?.value,
               let mins = Int(minsStr), mins > 0 {
                timerViewModel.selectSessionType(.pomodoro)
                timerViewModel.timerService.start(duration: mins)
            } else {
                timerViewModel.startFocus()
            }
        case "pause":
            timerViewModel.pause()
        case "toggle":
            timerViewModel.togglePauseResume()
        case "skip":
            timerViewModel.skip()
        case "reset":
            timerViewModel.reset()
        default:
            break
        }
    }
}

@main
struct FocusBarApp: App {
    @NSApplicationDelegateAdaptor(FocusBarAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
