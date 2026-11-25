import SwiftUI
import SwiftData
import AppKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    var timerViewModel: TimerViewModel?
    @State private var viewModel = SettingsViewModel()
    @State private var newPresetName: String = ""
    @State private var dataError: AppError?
    @State private var dataStatusMessage: String?
    @State private var confirmingReset = false
    private let exportService = ExportService()
    private let soundService = SoundService()

    var body: some View {
        TabView {
            timerTab
                .tabItem { Label("Timer", systemImage: "timer") }
            audioTab
                .tabItem { Label("Audio", systemImage: "speaker.wave.2") }
            integrationsTab
                .tabItem { Label("Integrations", systemImage: "bolt.horizontal") }
            displayTab
                .tabItem { Label("Display", systemImage: "menubar.rectangle") }
            goalsTab
                .tabItem { Label("Goals", systemImage: "target") }
            dataTab
                .tabItem { Label("Data", systemImage: "square.and.arrow.up") }
            aboutTab
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(minWidth: 520, minHeight: 440)
    }

    // MARK: - Timer

    private var timerTab: some View {
        Form {
            Section("Built-in Presets") {
                HStack(spacing: 8) {
                    ForEach(TimerPreset.builtInDefaults) { preset in
                        Button(preset.name) {
                            viewModel.applyPreset(preset)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }

            Section("Custom Presets") {
                if !viewModel.customPresets.isEmpty {
                    ForEach(viewModel.customPresets) { preset in
                        HStack {
                            Button("\(preset.name) (\(preset.focusMinutes)/\(preset.shortBreakMinutes)/\(preset.longBreakMinutes))") {
                                viewModel.applyPreset(preset)
                            }
                            .buttonStyle(.plain)
                            Spacer()
                            Button(role: .destructive) {
                                viewModel.deleteCustomPreset(preset)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                HStack {
                    TextField("New preset name (e.g. Deep Work)", text: $newPresetName)
                    Button("Save Current") {
                        viewModel.saveCurrentAsPreset(name: newPresetName)
                        newPresetName = ""
                    }
                    .disabled(newPresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            Section("Session Durations") {
                Stepper("Focus: \(viewModel.pomodoroDuration) min", value: $viewModel.pomodoroDuration, in: 1...120)
                    .monospacedDigit()
                Stepper("Short Break: \(viewModel.shortBreakDuration) min", value: $viewModel.shortBreakDuration, in: 1...60)
                    .monospacedDigit()
                Stepper("Long Break: \(viewModel.longBreakDuration) min", value: $viewModel.longBreakDuration, in: 1...120)
                    .monospacedDigit()
            }

            Section("Cycle & Flow") {
                Stepper("Sessions until long break: \(viewModel.sessionsUntilLongBreak)", value: $viewModel.sessionsUntilLongBreak, in: 1...12)
                    .monospacedDigit()
                Toggle("Auto-start breaks", isOn: $viewModel.autoStartBreaks)
                Toggle("Auto-start focus sessions", isOn: $viewModel.autoStartFocus)
                Toggle("Overtime mode (count up past 00:00)", isOn: $viewModel.overtimeEnabled)
                Toggle("Full-screen break overlay", isOn: $viewModel.breakOverlayEnabled)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Audio & Notifications

    private var audioTab: some View {
        Form {
            Section("Notifications") {
                Toggle("Notification Banners", isOn: $viewModel.bannerEnabled)
                Toggle("Completion Sound", isOn: $viewModel.soundEnabled)
            }

            Section("Chimes") {
                HStack {
                    Picker("Focus Complete", selection: $viewModel.focusEndSound) {
                        ForEach(ChimeSound.allCases, id: \.rawValue) { sound in
                            Text(sound.displayName).tag(sound.rawValue)
                        }
                    }
                    Button("Preview") {
                        let sound = ChimeSound(rawValue: viewModel.focusEndSound) ?? .glass
                        soundService.playChime(sound, volume: Float(viewModel.soundVolume))
                    }
                    .controlSize(.small)
                }

                HStack {
                    Picker("Break Complete", selection: $viewModel.breakEndSound) {
                        ForEach(ChimeSound.allCases, id: \.rawValue) { sound in
                            Text(sound.displayName).tag(sound.rawValue)
                        }
                    }
                    Button("Preview") {
                        let sound = ChimeSound(rawValue: viewModel.breakEndSound) ?? .ping
                        soundService.playChime(sound, volume: Float(viewModel.soundVolume))
                    }
                    .controlSize(.small)
                }

                Slider(value: $viewModel.soundVolume, in: 0...1) {
                    Text("Chime Volume")
                }
            }

            Section("Offline Ambient Soundscape") {
                Picker("Focus Sound", selection: $viewModel.ambientSoundMode) {
                    ForEach(AmbientSoundMode.allCases, id: \.rawValue) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                }
                .onChange(of: viewModel.ambientSoundMode) { _, newValue in
                    if let mode = AmbientSoundMode(rawValue: newValue) {
                        timerViewModel?.ambientSoundMode = mode
                    }
                }

                Slider(value: $viewModel.ambientVolume, in: 0...1) {
                    Text("Ambient Volume")
                }
                .onChange(of: viewModel.ambientVolume) { _, newVol in
                    timerViewModel?.soundService.updateAmbientVolume(Float(newVol))
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Integrations

    private var integrationsTab: some View {
        Form {
            Section("Global Keyboard Shortcuts") {
                Toggle("Enable Global Hotkeys", isOn: $viewModel.globalHotkeysEnabled)
                    .onChange(of: viewModel.globalHotkeysEnabled) { _, _ in
                        timerViewModel?.refreshHotkeysFromDefaults()
                    }
                Text("Start/Pause: Ctrl + Opt + Cmd + S   ·   Reset: + R   ·   Skip: + N")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Apple Calendar") {
                Toggle("Log completed focus sessions to Calendar", isOn: $viewModel.calendarSyncEnabled)
                TextField("Calendar Name", text: $viewModel.calendarName)
            }

            Section("Idle & Distraction Guard") {
                Toggle("Detect away/idle time during focus", isOn: $viewModel.idleDetectionEnabled)
                Stepper("Idle threshold: \(viewModel.idleThresholdMinutes) min", value: $viewModel.idleThresholdMinutes, in: 1...30)
                    .monospacedDigit()
                Toggle("Nudge when distracting apps activate", isOn: $viewModel.distractionGuardEnabled)
                TextField("Blocked bundle IDs (comma-separated)", text: $viewModel.blockedBundleIDs)
                Text("Example: com.tinyspeck.slackmacgap, com.hnc.Discord")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Display

    private var displayTab: some View {
        Form {
            Section("Menu Bar") {
                Picker("Display Mode", selection: $viewModel.menuBarDisplayMode) {
                    ForEach(MenuBarDisplayMode.allCases, id: \.rawValue) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                }
                Toggle("Show estimated end time (e.g. 23:57 · 11:30)", isOn: $viewModel.showEndTimeInMenuBar)
            }
            Section("Floating Widget") {
                Picker("Widget Size", selection: $viewModel.floatingWidgetSize) {
                    ForEach(FloatingWidgetSize.allCases, id: \.self) { sizeOption in
                        Text(sizeOption.displayName).tag(sizeOption.rawValue)
                    }
                }
                .onChange(of: viewModel.floatingWidgetSize) { _, newValue in
                    if let sizeOption = FloatingWidgetSize(rawValue: newValue) {
                        timerViewModel?.floatingWidgetSize = sizeOption
                    }
                }
                Button("Toggle Floating Widget") {
                    timerViewModel?.toggleFloatingTimer()
                }
                Text("Drag anywhere on screen to place. Right-click the widget to switch sizes or lock its position.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Startup") {
                Toggle("Launch at Login", isOn: Binding(
                    get: { viewModel.launchAtLogin },
                    set: { viewModel.setLaunchAtLogin($0) }
                ))
                if let error = viewModel.launchAtLoginError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Goals

    private var goalsTab: some View {
        Form {
            Section("Daily Goal") {
                Stepper("Pomodoros per day: \(viewModel.dailyGoal)", value: $viewModel.dailyGoal, in: 1...20)
                    .monospacedDigit()
                Text("Complete this many focus sessions to maintain your daily streak.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Data

    private var dataTab: some View {
        Form {
            Section("Export") {
                HStack(spacing: 12) {
                    Button("Export JSON Backup...") {
                        runDataTask {
                            let sessions = try modelContext.fetch(FetchDescriptor<Session>())
                            let achievements = try modelContext.fetch(FetchDescriptor<Achievement>())
                            let stats = try modelContext.fetch(FetchDescriptor<DailyStats>())
                            if let url = try await exportService.exportAll(
                                sessions: sessions,
                                achievements: achievements,
                                dailyStats: stats
                            ) {
                                dataStatusMessage = "Exported JSON to \(url.lastPathComponent)"
                            }
                        }
                    }

                    Button("Export CSV...") {
                        runDataTask {
                            let sessions = try modelContext.fetch(FetchDescriptor<Session>())
                            if let url = try await exportService.exportCSV(sessions: sessions) {
                                dataStatusMessage = "Exported CSV to \(url.lastPathComponent)"
                            }
                        }
                    }
                }
            }

            Section("Restore") {
                Button("Import JSON Backup...") {
                    runDataTask {
                        if let summary = try await exportService.importFromJSON(modelContext: modelContext) {
                            dataStatusMessage = "Imported \(summary.sessionsImported) sessions, \(summary.achievementsImported) badges, \(summary.dailyStatsImported) daily records"
                        }
                    }
                }
            }

            Section("Reset") {
                Button("Reset All Local Data...", role: .destructive) {
                    confirmingReset = true
                }
                .confirmationDialog(
                    "Reset all FocusBar sessions, achievements, XP, and streaks?",
                    isPresented: $confirmingReset,
                    titleVisibility: .visible
                ) {
                    Button("Reset Everything", role: .destructive) {
                        do {
                            try exportService.resetAllData(modelContext: modelContext)
                            dataStatusMessage = "All local data has been reset."
                        } catch {
                            dataError = .dataError(error.localizedDescription)
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }

            if let dataStatusMessage {
                Text(dataStatusMessage)
                    .font(.caption)
                    .foregroundStyle(.green)
            }
            if let dataError {
                Text(dataError.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - About

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
                        Text("100% Free & Open Source (MIT License)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Updates") {
                HStack {
                    Button(viewModel.isCheckingUpdates ? "Checking..." : "Check for Updates") {
                        Task { await viewModel.checkForUpdates() }
                    }
                    .disabled(viewModel.isCheckingUpdates)

                    Spacer()

                    if let status = viewModel.updateStatus {
                        switch status {
                        case .upToDate(let current):
                            Text("Up to date (v\(current))")
                                .font(.caption)
                                .foregroundStyle(.green)
                        case .updateAvailable(let latest, let url):
                            Link("Download \(latest)", destination: url)
                                .font(.caption.weight(.semibold))
                        case .failed(let message):
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .lineLimit(1)
                        }
                    }
                }
            }

            Section("Links") {
                if let websiteURL = URL(string: Constants.websiteURL) {
                    Link("FocusBar Website", destination: websiteURL)
                }
                if let feedbackURL = URL(string: Constants.feedbackURL) {
                    Link("Report an Issue on GitHub", destination: feedbackURL)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func runDataTask(_ action: @escaping () async throws -> Void) {
        dataError = nil
        dataStatusMessage = nil
        Task {
            do {
                try await action()
            } catch let error as AppError {
                dataError = error
            } catch {
                dataError = .dataError(error.localizedDescription)
            }
        }
    }
}
