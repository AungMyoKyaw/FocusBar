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

    private var totalBonusXPEarned: Int {
        Constants.achievements
            .filter { unlockedIds.contains($0.id) }
            .reduce(0) { $0 + $1.xpBonus }
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
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Achievements")
                        .font(.title.bold())
                    Text("Milestones across focus, streaks, and tasks")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                progressSummaryCard

                if visibleCategories.isEmpty {
                    ContentUnavailableView(
                        filter == .unlocked ? "No Achievements Unlocked Yet" : "All Achievements Unlocked",
                        systemImage: "trophy",
                        description: Text(filter == .unlocked ? "Complete focus sessions to unlock your first badge." : "Every achievement has been earned.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 240)
                    .focusCardSurface()
                } else {
                    ForEach(visibleCategories, id: \.self) { category in
                        achievementSection(for: category)
                    }
                }
            }
            .frame(maxWidth: 820, alignment: .leading)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .frame(minWidth: 580, minHeight: 480)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Filter", selection: $filter) {
                    ForEach(Filter.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .accessibilityLabel("Achievement filter")
            }
        }
    }

    private var progressSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(unlockedAchievements.count) of \(Constants.achievements.count) unlocked")
                    .font(.headline)
                    .monospacedDigit()

                Spacer()

                Text("+\(totalBonusXPEarned) XP earned")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(FocusBarTheme.shortBreakAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(FocusBarTheme.shortBreakAccent.opacity(0.14), in: Capsule())

                Text("\(Int(unlockProgress * 100))%")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(FocusBarTheme.focusAccent)
            }

            GeometryReader { geo in
                let clamped = min(max(unlockProgress, 0), 1)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                    if clamped > 0 {
                        Capsule()
                            .fill(FocusBarTheme.focusAccent)
                            .frame(width: max(6, geo.size.width * clamped))
                    }
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .focusCardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(unlockedAchievements.count) of \(Constants.achievements.count) achievements unlocked, \(totalBonusXPEarned) bonus XP earned")
    }

    private func achievementSection(for category: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(category)
                .font(.headline)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 260), spacing: 12)],
                spacing: 12
            ) {
                ForEach(filteredDefinitions(for: category), id: \.id) { def in
                    let unlocked = unlockedIds.contains(def.id)
                    let achievement = unlocked ? unlockedAchievements.first(where: { $0.type == def.id }) : nil
                    achievementCard(def: def, unlocked: unlocked, unlockedAt: achievement?.unlockedAt)
                }
            }
        }
    }

    private func achievementCard(
        def: Constants.AchievementDefinition,
        unlocked: Bool,
        unlockedAt: Date?
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: unlocked ? "checkmark.seal.fill" : "seal")
                .font(.title3)
                .foregroundStyle(unlocked ? FocusBarTheme.shortBreakAccent : .secondary)
                .frame(width: 32, height: 32)
                .background(
                    (unlocked ? FocusBarTheme.shortBreakAccent : Color.primary).opacity(unlocked ? 0.14 : 0.06),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(def.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(unlocked ? .primary : .secondary)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    Text("+\(def.xpBonus) XP")
                        .font(.caption2.bold())
                        .monospacedDigit()
                        .foregroundStyle(unlocked ? FocusBarTheme.shortBreakAccent : .secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            (unlocked ? FocusBarTheme.shortBreakAccent : Color.secondary).opacity(0.12),
                            in: Capsule()
                        )
                }

                Text(def.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if let unlockedAt {
                    Text(unlockedAt, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .focusCardSurface()
        .opacity(unlocked ? 1.0 : 0.72)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(def.title), \(def.description), \(unlocked ? "Unlocked" : "Locked"), \(def.xpBonus) XP bonus")
    }
}
