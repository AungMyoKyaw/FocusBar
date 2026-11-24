import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Query private var unlockedAchievements: [Achievement]
    @State private var filter: Filter = .all

    private enum Filter: String, CaseIterable {
        case all = "All"
        case unlocked = "Unlocked"
        case locked = "Locked"
    }

    private static let categoryOrder = [
        "Getting Started",
        "Daily Intensity",
        "Consistency",
        "Volume",
        "Time Based",
        "Task Mastery",
    ]

    private var unlockedIds: Set<String> {
        Set(unlockedAchievements.map(\.type))
    }

    private var unlockProgress: Double {
        guard !Constants.achievements.isEmpty else { return 0 }
        return Double(unlockedAchievements.count) / Double(Constants.achievements.count)
    }

    private var visibleCategories: [String] {
        Self.categoryOrder.filter { !filteredDefinitions(for: $0).isEmpty }
    }

    private func filteredDefinitions(for category: String) -> [Constants.AchievementDefinition] {
        Constants.achievements.filter { def in
            guard def.category == category else { return false }
            let isUnlocked = unlockedIds.contains(def.id)
            switch filter {
            case .all: return true
            case .unlocked: return isUnlocked
            case .locked: return !isUnlocked
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Achievements")
                        .font(.title.bold())
                    Spacer()
                    Picker("Filter", selection: $filter) {
                        ForEach(Filter.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                    .accessibilityLabel("Achievement filter")
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(unlockedAchievements.count) of \(Constants.achievements.count) unlocked")
                            .font(.subheadline)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(unlockProgress * 100))%")
                            .font(.subheadline.weight(.medium))
                            .monospacedDigit()
                            .foregroundStyle(FocusBarTheme.focusAccent)
                    }
                    ProgressView(value: unlockProgress)
                        .tint(FocusBarTheme.focusAccent)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(unlockedAchievements.count) of \(Constants.achievements.count) achievements unlocked")

                if visibleCategories.isEmpty {
                    ContentUnavailableView(
                        filter == .unlocked ? "No Achievements Unlocked Yet" : "All Achievements Unlocked",
                        systemImage: "trophy",
                        description: Text(filter == .unlocked ? "Complete focus sessions to unlock your first badge." : "Every achievement has been earned.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 240)
                } else {
                    ForEach(visibleCategories, id: \.self) { category in
                        achievementSection(for: category)
                    }
                }
            }
            .padding(20)
        }
        .frame(width: 520, height: 520)
    }

    private func achievementSection(for category: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category)
                .font(.headline)

            ForEach(filteredDefinitions(for: category), id: \.id) { def in
                let unlocked = unlockedIds.contains(def.id)
                HStack(spacing: 12) {
                    Image(systemName: unlocked ? "checkmark.seal.fill" : "seal")
                        .foregroundStyle(unlocked ? FocusBarTheme.shortBreakAccent : .secondary)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(def.title)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(unlocked ? .primary : .secondary)
                        Text(def.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if unlocked, let achievement = unlockedAchievements.first(where: { $0.type == def.id }) {
                        Text(achievement.unlockedAt, style: .date)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Text("+\(def.xpBonus) XP")
                        .font(.caption.bold())
                        .monospacedDigit()
                        .foregroundStyle(unlocked ? FocusBarTheme.shortBreakAccent : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            (unlocked ? FocusBarTheme.shortBreakAccent : Color.secondary).opacity(0.12),
                            in: Capsule()
                        )
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(def.title), \(def.description), \(unlocked ? "Unlocked" : "Locked"), \(def.xpBonus) XP bonus")
            }
        }
    }
}
