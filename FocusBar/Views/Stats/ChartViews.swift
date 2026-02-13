import SwiftUI
import Charts

struct FocusByHourChart: View {
    let data: [(hour: Int, count: Int)]

    var body: some View {
        Chart(data, id: \.hour) { item in
            BarMark(
                x: .value("Hour", item.hour),
                y: .value("Sessions", item.count)
            )
            .foregroundStyle(.green.gradient)
        }
        .chartXAxisLabel("Hour of Day")
        .chartYAxisLabel("Sessions")
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
            .foregroundStyle(.blue.gradient)
        }
        .chartXAxisLabel("Focus Minutes")
    }
}
