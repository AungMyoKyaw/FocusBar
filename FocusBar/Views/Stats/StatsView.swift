import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = StatsViewModel()

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

                VStack(alignment: .leading, spacing: 2) {
                    Text("Statistics")
                        .font(.title.bold())
                    Text(viewModel.timeRange.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
                }
            }
            .frame(maxWidth: 860, alignment: .leading)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .frame(minWidth: 620, minHeight: 480)
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

            Text("Complete a focus session to see your hourly distribution and task breakdown.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 24)
        .focusCardSurface()
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
