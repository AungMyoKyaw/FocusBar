import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SettingsViewModel()
    private let exportService = ExportService()

    var body: some View {
        TabView {
            timerTab
                .tabItem { Label("Timer", systemImage: "timer") }
            notificationsTab
                .tabItem { Label("Notifications", systemImage: "bell") }
            displayTab
                .tabItem { Label("Display", systemImage: "menubar.rectangle") }
            goalsTab
                .tabItem { Label("Goals", systemImage: "target") }
            dataTab
                .tabItem { Label("Data", systemImage: "square.and.arrow.up") }
        }
        .frame(width: 420, height: 320)
        .padding()
    }

    private var timerTab: some View {
        Form {
            Section("Focus Duration") {
                Stepper("Focus: \(viewModel.pomodoroDuration) min", value: $viewModel.pomodoroDuration, in: 1...120)
                Stepper("Short Break: \(viewModel.shortBreakDuration) min", value: $viewModel.shortBreakDuration, in: 1...60)
                Stepper("Long Break: \(viewModel.longBreakDuration) min", value: $viewModel.longBreakDuration, in: 1...120)
            }
            Section("Cycle") {
                Stepper("Sessions until long break: \(viewModel.sessionsUntilLongBreak)", value: $viewModel.sessionsUntilLongBreak, in: 1...12)
            }
        }
    }

    private var notificationsTab: some View {
        Form {
            Section("Alerts") {
                Toggle("Notification Banner", isOn: $viewModel.bannerEnabled)
                Toggle("Sound", isOn: $viewModel.soundEnabled)
                Toggle("Screen Overlay on Break", isOn: $viewModel.overlayEnabled)
            }
        }
    }

    private var displayTab: some View {
        Form {
            Section("Menu Bar") {
                Picker("Display Mode", selection: $viewModel.menuBarDisplayMode) {
                    ForEach(MenuBarDisplayMode.allCases, id: \.rawValue) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                }
            }
        }
    }

    private var goalsTab: some View {
        Form {
            Section("Daily Goal") {
                Stepper("Pomodoros per day: \(viewModel.dailyGoal)", value: $viewModel.dailyGoal, in: 1...20)
                Text("Complete this many focus sessions to maintain your streak.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var dataTab: some View {
        Form {
            Section("Export") {
                Button("Export All Data to JSON...") {
                    Task {
                        let sessions = (try? modelContext.fetch(FetchDescriptor<Session>())) ?? []
                        let achievements = (try? modelContext.fetch(FetchDescriptor<Achievement>())) ?? []
                        let stats = (try? modelContext.fetch(FetchDescriptor<DailyStats>())) ?? []
                        _ = try? await exportService.exportAll(
                            sessions: sessions,
                            achievements: achievements,
                            dailyStats: stats
                        )
                    }
                }
                Text("Exports sessions, achievements, stats, and preferences to a JSON file.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
