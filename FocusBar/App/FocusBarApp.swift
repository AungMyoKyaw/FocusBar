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
            UserDefaultsKeys.soundEnabled: false,
            UserDefaultsKeys.autoStartNextSession: false,
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
        _timerViewModel = State(initialValue: vm)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(timerViewModel: timerViewModel)
                .modelContainer(sharedModelContainer)
        } label: {
            TimerDisplayView(timerViewModel: timerViewModel)
        }
        .menuBarExtraStyle(.window)

        Window("Onboarding", id: "onboarding") {
            OnboardingContainerView()
        }
        .windowResizability(.contentSize)

        Window("Settings", id: "settings") {
            SettingsView()
                .modelContainer(sharedModelContainer)
        }
        .defaultSize(width: 520, height: 420)
        .windowResizability(.contentSize)

        Window("Statistics", id: "stats") {
            StatsView()
                .modelContainer(sharedModelContainer)
        }
        .defaultSize(width: 720, height: 580)

        Window("Achievements", id: "achievements") {
            AchievementsView()
                .modelContainer(sharedModelContainer)
        }
        .defaultSize(width: 660, height: 580)
    }
}
