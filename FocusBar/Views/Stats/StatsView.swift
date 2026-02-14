import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = StatsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Statistics")
                        .font(.largeTitle.bold())
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

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(title: "Focus Hours", value: String(format: "%.1f", viewModel.totalFocusHours), icon: "timer")
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Focus Hours: \(String(format: "%.1f", viewModel.totalFocusHours))")
                    StatCard(title: "Sessions", value: "\(viewModel.totalSessions)", icon: "checkmark.circle")
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Sessions: \(viewModel.totalSessions)")
                    StatCard(title: "Avg Length", value: "\(viewModel.averageSessionMinutes) min", icon: "clock")
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Average session length: \(viewModel.averageSessionMinutes) minutes")
                    StatCard(title: "Best Day", value: "\(viewModel.bestDayPomodoros) 🍅", icon: "star")
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Best day: \(viewModel.bestDayPomodoros) pomodoros")
                }

                GroupBox("Focus by Hour") {
                    FocusByHourChart(data: viewModel.focusByHour)
                        .frame(height: 180)
                        .accessibilityLabel("Bar chart showing focus sessions by hour of day")
                }

                if !viewModel.taskBreakdown.isEmpty {
                    GroupBox("Time by Task") {
                        TaskBreakdownChart(data: viewModel.taskBreakdown)
                            .frame(height: 180)
                            .accessibilityLabel("Bar chart showing focus minutes by task")
                    }
                }
            }
            .padding()
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

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.green)
            Text(value)
                .font(.title3.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}
