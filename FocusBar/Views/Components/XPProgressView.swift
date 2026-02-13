import SwiftUI

struct XPProgressView: View {
    let currentXP: Int
    let currentLevel: Int
    let levelTitle: String
    let xpProgress: Double
    let currentStreak: Int

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Label("Lv.\(currentLevel)", systemImage: "leaf.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
                Spacer()
                if currentStreak > 0 {
                    Label("\(currentStreak)", systemImage: "flame.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                }
            }

            ProgressView(value: xpProgress)
                .tint(.green)

            Text("\(levelTitle) — \(currentXP) XP")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
