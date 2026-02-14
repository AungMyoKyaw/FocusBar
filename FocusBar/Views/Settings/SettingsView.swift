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
            aboutTab
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 420, height: 340)
        .padding()
    }

    private var timerTab: some View {
        Form {
            Section("Focus Duration") {
                Stepper("Focus: \(viewModel.pomodoroDuration) min", value: $viewModel.pomodoroDuration, in: 1...120)
                    .accessibilityValue("\(viewModel.pomodoroDuration) minutes")
                    .accessibilityHint("Adjusts the focus session duration")
                Stepper("Short Break: \(viewModel.shortBreakDuration) min", value: $viewModel.shortBreakDuration, in: 1...60)
                    .accessibilityValue("\(viewModel.shortBreakDuration) minutes")
                    .accessibilityHint("Adjusts the short break duration")
                Stepper("Long Break: \(viewModel.longBreakDuration) min", value: $viewModel.longBreakDuration, in: 1...120)
                    .accessibilityValue("\(viewModel.longBreakDuration) minutes")
                    .accessibilityHint("Adjusts the long break duration")
            }
            Section("Cycle") {
                Stepper("Sessions until long break: \(viewModel.sessionsUntilLongBreak)", value: $viewModel.sessionsUntilLongBreak, in: 1...12)
                    .accessibilityValue("\(viewModel.sessionsUntilLongBreak) sessions")
                    .accessibilityHint("Adjusts how many focus sessions before a long break")
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
                    .accessibilityValue("\(viewModel.dailyGoal) pomodoros")
                    .accessibilityHint("Adjusts the daily focus session goal")
                Text("Complete this many focus sessions to maintain your streak.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var aboutTab: some View {
        Form {
            Section("Application") {
                LabeledContent("Version", value: Constants.appVersion)
                    .accessibilityValue("Version \(Constants.appVersion)")
                LabeledContent("Build", value: Constants.appBuildNumber)
                    .accessibilityValue("Build \(Constants.appBuildNumber)")
            }
            Section("Feedback") {
                Link("Send Feedback", destination: URL(string: Constants.feedbackURL)!)
                    .accessibilityHint("Opens your email client to send feedback")
            }
            Section("Credits") {
                Text("FocusBar — A Pomodoro timer for your menu bar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Built with SwiftUI")
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
                .accessibilityHint("Exports all session data to a JSON file")
                Text("Exports sessions, achievements, stats, and preferences to a JSON file.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
