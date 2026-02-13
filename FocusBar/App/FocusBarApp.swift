import SwiftUI
import SwiftData

@main
struct FocusBarApp: App {
    @State private var timerViewModel = TimerViewModel()

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
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(timerViewModel: timerViewModel)
                .modelContainer(sharedModelContainer)
        } label: {
            Text(timerViewModel.menuBarTitle)
        }
        .menuBarExtraStyle(.window)

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
