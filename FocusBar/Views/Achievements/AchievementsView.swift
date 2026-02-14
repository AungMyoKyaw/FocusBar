import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Query private var unlockedAchievements: [Achievement]

    private var unlockedIds: Set<String> {
        Set(unlockedAchievements.map(\.type))
    }

    private var categories: [String] {
        let cats = Constants.achievements.map(\.category)
        return Array(Set(cats)).sorted()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Achievements")
                    .font(.largeTitle.bold())
                    .padding(.bottom, 4)

                Text("\(unlockedAchievements.count)/\(Constants.achievements.count) unlocked")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("\(unlockedAchievements.count) of \(Constants.achievements.count) achievements unlocked")

                ForEach(categories, id: \.self) { category in
                    achievementSection(for: category)
                }
            }
            .padding()
        }
        .frame(width: 500, height: 500)
    }

    private func achievementSection(for category: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category)
                .font(.headline)

            let defs = Constants.achievements.filter { $0.category == category }
            ForEach(defs, id: \.id) { def in
                let unlocked = unlockedIds.contains(def.id)
                HStack {
                    Image(systemName: unlocked ? "checkmark.seal.fill" : "seal")
                        .foregroundStyle(unlocked ? .green : .secondary)
                        .font(.title3)

                    VStack(alignment: .leading) {
                        Text(def.title)
                            .font(.body.bold())
                            .foregroundStyle(unlocked ? .primary : .secondary)
                        Text(def.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if unlocked {
                        if let achievement = unlockedAchievements.first(where: { $0.type == def.id }) {
                            Text(achievement.unlockedAt, style: .date)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text("+\(def.xpBonus) XP")
                        .font(.caption.bold())
                        .foregroundStyle(unlocked ? .green : .secondary)
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(def.title), \(def.description), \(unlocked ? "Unlocked" : "Locked"), \(def.xpBonus) XP bonus")
            }
        }
    }
}
