import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = StatsViewModel()
    @State private var showingManualEntry = false

    private var peakHourSummary: String? {
        guard let peak = viewModel.focusByHour.max(by: { $0.count < $1.count }), peak.count > 0 else {
            return nil
        }
        return "Peak: \(FocusByHourChart.fullHourLabel(peak.hour))"
    }

    private var totalTaskMinutesSummary: String? {
        let total = viewModel.taskBreakdown.reduce(0) { $0 + $1.minutes }
        guard total > 0 else { return nil }
        return "\(total)m logged"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let error = viewModel.currentError {
                    ErrorBannerView(error: error) {
                        viewModel.currentError = nil
                    }
                }

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Statistics")
                            .font(.title.bold())
                        Text(viewModel.timeRange.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        showingManualEntry = true
                    } label: {
                        Label("Log Session", systemImage: "plus")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 135), spacing: 12)],
                    spacing: 12
                ) {
                    StatCard(
                        title: "Focus Hours",
                        value: String(format: "%.1f", viewModel.totalFocusHours),
                        unit: "hrs",
                        icon: "timer",
                        accent: FocusBarTheme.focusAccent
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Focus Hours: \(String(format: "%.1f", viewModel.totalFocusHours))")

                    StatCard(
                        title: "Sessions",
                        value: "\(viewModel.totalSessions)",
                        icon: "checkmark.circle",
                        accent: FocusBarTheme.shortBreakAccent
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Sessions: \(viewModel.totalSessions)")

                    StatCard(
                        title: "Avg Length",
                        value: "\(viewModel.averageSessionMinutes)",
                        unit: "min",
                        icon: "clock",
                        accent: FocusBarTheme.longBreakAccent
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Average session length: \(viewModel.averageSessionMinutes) minutes")

                    StatCard(
                        title: "Best Day",
                        value: "\(viewModel.bestDayPomodoros)",
                        unit: viewModel.bestDayPomodoros == 1 ? "session" : "sessions",
                        icon: "flame.fill",
                        accent: FocusBarTheme.streakAccent
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Best day: \(viewModel.bestDayPomodoros) pomodoros")
                }

                if !viewModel.heatmapDays.isEmpty {
                    DashboardChartCard(title: "16-Week Activity", badge: "Last 112 days") {
                        FocusHeatmapChart(days: viewModel.heatmapDays)
                    }
                }

                if viewModel.totalSessions == 0 {
                    emptyStateCard
                } else {
                    DashboardChartCard(title: "Focus by Hour", badge: peakHourSummary) {
                        FocusByHourChart(data: viewModel.focusByHour)
                            .frame(height: 200)
                    }

                    if !viewModel.taskBreakdown.isEmpty {
                        DashboardChartCard(title: "Time by Task", badge: totalTaskMinutesSummary) {
                            TaskBreakdownChart(data: viewModel.taskBreakdown)
                                .frame(height: max(160, CGFloat(min(viewModel.taskBreakdown.count, 8)) * 30))
                        }
                    }

                    DashboardChartCard(title: "Recent Sessions", badge: "\(viewModel.completedPomodoros.count) total") {
                        VStack(spacing: 8) {
                            ForEach(viewModel.completedPomodoros.prefix(25), id: \.id) { session in
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(FocusBarTheme.focusAccent)
                                        .frame(width: 6, height: 6)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(session.displayTaskTitle)
                                            .font(.subheadline.weight(.medium))
                                            .lineLimit(1)
                                        Text(session.startTime.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    if let tag = session.tag, !tag.isEmpty {
                                        Text("#\(tag)")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(FocusBarTheme.longBreakAccent)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(FocusBarTheme.longBreakAccent.opacity(0.14), in: Capsule())
                                    }

                                    Text("\(max(1, session.duration / 60))m")
                                        .font(.caption.weight(.semibold))
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)

                                    Button(role: .destructive) {
                                        viewModel.deleteSession(session, modelContext: modelContext)
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Delete session")
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: 860, alignment: .leading)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .frame(minWidth: 640, minHeight: 500)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Range", selection: $viewModel.timeRange) {
                    ForEach(StatsViewModel.TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .accessibilityLabel("Time range filter")
                .accessibilityValue(viewModel.timeRange.rawValue)
            }
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualSessionSheet { minutes, task, tag, notes, date in
                viewModel.addManualSession(
                    durationMinutes: minutes,
                    taskTitle: task,
                    tag: tag,
                    notes: notes,
                    date: date,
                    modelContext: modelContext
                )
            }
        }
        .onAppear { viewModel.loadStats(modelContext: modelContext) }
        .onChange(of: viewModel.timeRange) { viewModel.loadStats(modelContext: modelContext) }
    }

    private var emptyStateCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 2)
                    .frame(width: 56, height: 56)
                Image(systemName: "timer")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Text("No Completed Sessions")
                .font(.headline)

            Text("Complete a focus session or click Log Session to record offline deep work.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 24)
        .focusCardSurface()
    }
}

private struct ManualSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var durationMinutes: Int = 25
    @State private var taskTitle: String = ""
    @State private var selectedTag: String = ""
    @State private var notes: String = ""
    @State private var date: Date = Date()

    let onSave: (Int, String, String, String, Date) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Log Focus Session")
                .font(.headline)

            Form {
                Stepper("Duration: \(durationMinutes) min", value: $durationMinutes, in: 1...240)
                    .monospacedDigit()
                TextField("Task", text: $taskTitle)
                Picker("Tag", selection: $selectedTag) {
                    Text("None").tag("")
                    ForEach(Constants.defaultTags, id: \.self) { tag in
                        Text("#\(tag)").tag(tag)
                    }
                }
                DatePicker("Start Time", selection: $date)
                TextField("Notes (optional)", text: $notes)
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Button("Save Session") {
                    onSave(durationMinutes, taskTitle, selectedTag, notes, date)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 400)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    var unit: String? = nil
    let icon: String
    var accent: Color = FocusBarTheme.focusAccent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
                    .frame(width: 24, height: 24)
                    .background(accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)

                if let unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .focusCardSurface()
    }
}

private struct DashboardChartCard<Content: View>: View {
    let title: String
    var badge: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title)
                    .font(.headline)

                Spacer()

                if let badge {
                    Text(badge)
                        .font(.caption2.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.primary.opacity(0.06), in: Capsule())
                }
            }

            content
        }
        .padding(16)
        .focusCardSurface()
    }
}
