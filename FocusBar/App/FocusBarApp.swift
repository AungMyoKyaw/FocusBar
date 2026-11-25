import SwiftUI
import SwiftData
import AppKit

final class FocusBarAppDelegate: NSObject, NSApplicationDelegate {
    private var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if !UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasCompletedOnboarding) {
            showOnboardingWindow()
        }
    }

    @MainActor
    func showOnboardingWindow() {
        let controller = NSHostingController(
            rootView: OnboardingContainerView(onDismiss: { [weak self] in
                self?.onboardingWindow?.close()
                self?.onboardingWindow = nil
            })
        )
        let window = NSWindow(contentViewController: controller)
        window.title = "Welcome to FocusBar"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 480, height: 560))
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow = window
    }
}

@main
struct FocusBarApp: App {
    @NSApplicationDelegateAdaptor(FocusBarAppDelegate.self) private var appDelegate
    @State private var timerViewModel = TimerViewModel()

    let sharedModelContainer: ModelContainer

    init() {
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
        _timerViewModel = State(initialValue: vm)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(timerViewModel: timerViewModel)
                .modelContainer(sharedModelContainer)
                .onOpenURL { url in
                    handleURL(url)
                }
        } label: {
            TimerDisplayView(timerViewModel: timerViewModel)
        }
        .menuBarExtraStyle(.window)

        Window("Onboarding", id: "onboarding") {
            OnboardingContainerView()
        }
        .windowResizability(.contentSize)

        Window("Settings", id: "settings") {
            SettingsView(timerViewModel: timerViewModel)
                .modelContainer(sharedModelContainer)
        }
        .defaultSize(width: 560, height: 480)
        .windowResizability(.contentSize)

        Window("Statistics", id: "stats") {
            StatsView()
                .modelContainer(sharedModelContainer)
        }
        .defaultSize(width: 760, height: 640)

        Window("Achievements", id: "achievements") {
            AchievementsView()
                .modelContainer(sharedModelContainer)
        }
        .defaultSize(width: 660, height: 580)
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
