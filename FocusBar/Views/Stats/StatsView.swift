import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = StatsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let error = viewModel.currentError {
                    ErrorBannerView(error: error) {
                        viewModel.currentError = nil
                    }
                }

                HStack {
                    Text("Statistics")
                        .font(.title.bold())
                    Spacer()
                    Picker("Range", selection: $viewModel.timeRange) {
                        ForEach(StatsViewModel.TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 240)
                    .accessibilityLabel("Time range filter")
                    .accessibilityValue(viewModel.timeRange.rawValue)
                }

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                    spacing: 12
                ) {
                    StatCard(
                        title: "Focus Hours",
                        value: String(format: "%.1f", viewModel.totalFocusHours),
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
                        value: "\(viewModel.averageSessionMinutes) min",
                        icon: "clock",
                        accent: FocusBarTheme.longBreakAccent
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Average session length: \(viewModel.averageSessionMinutes) minutes")

                    StatCard(
                        title: "Best Day",
                        value: "\(viewModel.bestDayPomodoros)",
                        icon: "flame.fill",
                        accent: FocusBarTheme.streakAccent
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Best day: \(viewModel.bestDayPomodoros) pomodoros")
                }

                if viewModel.totalSessions == 0 {
                    ContentUnavailableView(
                        "No Completed Sessions",
                        systemImage: "timer",
                        description: Text("Complete a focus session to see your hourly distribution and task breakdown.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 260)
                } else {
                    GroupBox("Focus by Hour") {
                        FocusByHourChart(data: viewModel.focusByHour)
                            .frame(height: 180)
                            .padding(.top, 4)
                            .accessibilityLabel("Bar chart showing focus sessions by hour of day")
                    }

                    if !viewModel.taskBreakdown.isEmpty {
                        GroupBox("Time by Task") {
                            TaskBreakdownChart(data: viewModel.taskBreakdown)
                                .frame(height: 180)
                                .padding(.top, 4)
                                .accessibilityLabel("Bar chart showing focus minutes by task")
                        }
                    }
                }
            }
            .padding(20)
        }
        .frame(width: 560, height: 520)
        .onAppear { viewModel.loadStats(modelContext: modelContext) }
        .onChange(of: viewModel.timeRange) { viewModel.loadStats(modelContext: modelContext) }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var accent: Color = FocusBarTheme.focusAccent

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(accent)
            Text(value)
                .font(.title3.bold())
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: FocusBarTheme.cardCornerRadius))
    }
}
