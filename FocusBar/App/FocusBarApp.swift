import SwiftUI
import SwiftData

@main
struct FocusBarApp: App {
    @State private var timerViewModel = TimerViewModel()
    @AppStorage(UserDefaultsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @Environment(\.openWindow) private var openWindow

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Session.self,
            DailyStats.self,
            Achievement.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            LoggingService.logError(.dataError("ModelContainer creation failed: \(error.localizedDescription)"), context: "App initialization")
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [fallbackConfig])
        }
    }()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(timerViewModel: timerViewModel)
                .modelContainer(sharedModelContainer)
                .onAppear {
                    if !hasCompletedOnboarding {
                        openWindow(id: "onboarding")
                    }
                }
        } label: {
            Text(timerViewModel.menuBarTitle)
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

        Window("Statistics", id: "stats") {
            StatsView()
                .modelContainer(sharedModelContainer)
        }

        Window("Achievements", id: "achievements") {
            AchievementsView()
                .modelContainer(sharedModelContainer)
        }
    }
}
