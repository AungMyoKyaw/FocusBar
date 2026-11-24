import SwiftUI

struct XPProgressView: View {
    let currentXP: Int
    var xpForNextLevel: Int = 250
    let currentLevel: Int
    let levelTitle: String
    let xpProgress: Double
    let currentStreak: Int
    var accent: Color = FocusBarTheme.focusAccent

    var body: some View {
        VStack(spacing: 7) {
            HStack(spacing: 6) {
                Text("Lv.\(currentLevel)")
                    .font(.caption2.bold())
                    .monospacedDigit()
                    .foregroundStyle(accent)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(accent.opacity(0.14), in: Capsule())

                Text(levelTitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                if currentStreak > 0 {
                    Label("\(currentStreak)d", systemImage: "flame.fill")
                        .font(.caption2.bold())
                        .monospacedDigit()
                        .foregroundStyle(FocusBarTheme.streakAccent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(FocusBarTheme.streakAccent.opacity(0.14), in: Capsule())
                }

                Text("\(currentXP) / \(xpForNextLevel) XP")
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                let clamped = min(max(xpProgress, 0), 1)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                    Capsule()
                        .fill(accent)
                        .frame(width: max(4, geo.size.width * clamped))
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .focusCardSurface(cornerRadius: FocusBarTheme.controlCornerRadius)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Level \(currentLevel), \(levelTitle), \(currentXP) of \(xpForNextLevel) XP\(currentStreak > 0 ? ", \(currentStreak) day streak" : "")")
        .accessibilityValue("\(Int(xpProgress * 100)) percent to next level")
    }
}
