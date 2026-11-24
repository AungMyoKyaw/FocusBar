import SwiftUI
import Charts

struct FocusByHourChart: View {
    let data: [(hour: Int, count: Int)]
    @State private var selectedHour: Int?

    static func shortHourLabel(_ hour: Int) -> String {
        switch hour {
        case 0: return "12a"
        case 12: return "12p"
        case 1..<12: return "\(hour)a"
        default: return "\(hour - 12)p"
        }
    }

    static func fullHourLabel(_ hour: Int) -> String {
        switch hour {
        case 0: return "12 AM"
        case 12: return "12 PM"
        case 1..<12: return "\(hour) AM"
        default: return "\(hour - 12) PM"
        }
    }

    private var selectedDataPoint: (hour: Int, count: Int)? {
        guard let selectedHour else { return nil }
        return data.first(where: { $0.hour == selectedHour })
    }

    var body: some View {
        Chart {
            ForEach(data, id: \.hour) { item in
                BarMark(
                    x: .value("Hour", item.hour),
                    y: .value("Sessions", item.count)
                )
                .foregroundStyle(
                    selectedHour == nil || selectedHour == item.hour
                        ? AnyShapeStyle(FocusBarTheme.focusAccent.gradient)
                        : AnyShapeStyle(FocusBarTheme.focusAccent.opacity(0.35))
                )
                .cornerRadius(4)
            }

            if let match = selectedDataPoint {
                RuleMark(x: .value("Selected", match.hour))
                    .foregroundStyle(Color.primary.opacity(0.18))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .annotation(
                        position: .top,
                        spacing: 6,
                        overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                    ) {
                        Text("\(Self.fullHourLabel(match.hour)) · \(match.count) \(match.count == 1 ? "session" : "sessions")")
                            .font(.caption2.weight(.semibold))
                            .monospacedDigit()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.regularMaterial, in: Capsule())
                            .overlay(Capsule().strokeBorder(Color.primary.opacity(0.1), lineWidth: 1))
                    }
            }
        }
        .chartXSelection(value: $selectedHour)
        .chartXScale(domain: -0.5...23.5)
        .chartXAxis {
            AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
                    .foregroundStyle(Color.primary.opacity(0.08))
                AxisValueLabel {
                    if let hour = value.as(Int.self) {
                        Text(Self.shortHourLabel(hour))
                            .font(.caption2)
                            .monospacedDigit()
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) {
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
                    .foregroundStyle(Color.primary.opacity(0.08))
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Focus by hour chart with \(data.count) hours of data")
    }
}

struct TaskBreakdownChart: View {
    let data: [(title: String, minutes: Int)]

    var body: some View {
        Chart(data.prefix(8), id: \.title) { item in
            BarMark(
                x: .value("Minutes", item.minutes),
                y: .value("Task", item.title)
            )
            .foregroundStyle(FocusBarTheme.longBreakAccent.gradient)
            .cornerRadius(4)
            .annotation(position: .trailing, spacing: 6) {
                Text("\(item.minutes)m")
                    .font(.caption2.weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .chartXAxis {
            AxisMarks {
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
                    .foregroundStyle(Color.primary.opacity(0.08))
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks {
                AxisValueLabel()
                    .font(.caption)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Task breakdown chart showing \(min(data.count, 8)) tasks")
    }
}
