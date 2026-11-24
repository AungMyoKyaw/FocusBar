import SwiftUI
import SwiftData
import AppKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SettingsViewModel()
    @State private var exportError: AppError?
    @State private var exportStatusMessage: String?
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
        .frame(minWidth: 480, minHeight: 380)
    }

    private var timerTab: some View {
        Form {
            Section("Presets") {
                HStack(spacing: 8) {
                    Button("Classic 25/5") {
                        viewModel.pomodoroDuration = 25
                        viewModel.shortBreakDuration = 5
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button("Deep 50/10") {
                        viewModel.pomodoroDuration = 50
                        viewModel.shortBreakDuration = 10
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button("Sprint 15/3") {
                        viewModel.pomodoroDuration = 15
                        viewModel.shortBreakDuration = 3
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .accessibilityElement(children: .contain)
            }
            Section("Session Durations") {
                Stepper("Focus: \(viewModel.pomodoroDuration) min", value: $viewModel.pomodoroDuration, in: 1...120)
                    .monospacedDigit()
                    .accessibilityValue("\(viewModel.pomodoroDuration) minutes")
                    .accessibilityHint("Adjusts the focus session duration")
                Stepper("Short Break: \(viewModel.shortBreakDuration) min", value: $viewModel.shortBreakDuration, in: 1...60)
                    .monospacedDigit()
                    .accessibilityValue("\(viewModel.shortBreakDuration) minutes")
                    .accessibilityHint("Adjusts the short break duration")
                Stepper("Long Break: \(viewModel.longBreakDuration) min", value: $viewModel.longBreakDuration, in: 1...120)
                    .monospacedDigit()
                    .accessibilityValue("\(viewModel.longBreakDuration) minutes")
                    .accessibilityHint("Adjusts the long break duration")
            }
            Section("Cycle") {
                Stepper("Sessions until long break: \(viewModel.sessionsUntilLongBreak)", value: $viewModel.sessionsUntilLongBreak, in: 1...12)
                    .monospacedDigit()
                    .accessibilityValue("\(viewModel.sessionsUntilLongBreak) sessions")
                    .accessibilityHint("Adjusts how many focus sessions before a long break")
                Toggle("Auto-start next session", isOn: $viewModel.autoStartNextSession)
                    .accessibilityHint("Automatically starts the next focus or break session when one completes")
            }
        }
        .formStyle(.grouped)
    }

    private var notificationsTab: some View {
        Form {
            Section("Alerts") {
                Toggle("Notification Banner", isOn: $viewModel.bannerEnabled)
                Toggle("Sound", isOn: $viewModel.soundEnabled)
            }
        }
        .formStyle(.grouped)
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
            Section("Startup") {
                Toggle("Launch at Login", isOn: Binding(
                    get: { viewModel.launchAtLogin },
                    set: { viewModel.setLaunchAtLogin($0) }
                ))
                .accessibilityHint("Starts FocusBar automatically when you log in")
                if let error = viewModel.launchAtLoginError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var goalsTab: some View {
        Form {
            Section("Daily Goal") {
                Stepper("Pomodoros per day: \(viewModel.dailyGoal)", value: $viewModel.dailyGoal, in: 1...20)
                    .monospacedDigit()
                    .accessibilityValue("\(viewModel.dailyGoal) pomodoros")
                    .accessibilityHint("Adjusts the daily focus session goal")
                Text("Complete this many focus sessions to maintain your daily streak.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var aboutTab: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    if let icon = NSApp.applicationIconImage {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 48, height: 48)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("FocusBar")
                            .font(.headline)
                        Text("Version \(Constants.appVersion) (\(Constants.appBuildNumber))")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        Text("MIT License")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("FocusBar version \(Constants.appVersion) build \(Constants.appBuildNumber), MIT License")
            }
            Section("Support") {
                if let feedbackURL = URL(string: Constants.feedbackURL) {
                    Link("Report an Issue on GitHub", destination: feedbackURL)
                        .accessibilityHint("Opens FocusBar GitHub Issues in your browser")
                }
            }
        }
        .formStyle(.grouped)
    }

    private var dataTab: some View {
        Form {
            Section("Export") {
                Button("Export All Data to JSON...") {
                    exportError = nil
                    exportStatusMessage = nil
                    Task {
                        do {
                            let sessions = try modelContext.fetch(FetchDescriptor<Session>())
                            let achievements = try modelContext.fetch(FetchDescriptor<Achievement>())
                            let stats = try modelContext.fetch(FetchDescriptor<DailyStats>())
                            if let url = try await exportService.exportAll(
                                sessions: sessions,
                                achievements: achievements,
                                dailyStats: stats
                            ) {
                                exportStatusMessage = "Exported to \(url.lastPathComponent)"
                            }
                        } catch let error as AppError {
                            exportError = error
                        } catch {
                            exportError = .exportFailed(error.localizedDescription)
                        }
                    }
                }
                .accessibilityHint("Exports all session data to a JSON file")

                if let exportStatusMessage {
                    Text(exportStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                if let exportError {
                    Text(exportError.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Text("Exports sessions, achievements, daily stats, and preferences to a JSON file.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
