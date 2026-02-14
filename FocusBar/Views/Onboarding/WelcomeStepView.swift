import SwiftUI

struct WelcomeStepView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "timer")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)

            Text("Welcome to FocusBar")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Your menu bar Pomodoro timer with gamification")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "clock.fill", title: "Focus Timer", description: "25-minute Pomodoro sessions from your menu bar")
                FeatureRow(icon: "star.fill", title: "Earn XP & Level Up", description: "Gain experience and unlock achievements")
                FeatureRow(icon: "flame.fill", title: "Build Streaks", description: "Stay consistent and watch your streak grow")
                FeatureRow(icon: "checklist", title: "Link Reminders", description: "Connect sessions to your Apple Reminders")
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityLabel("Continue to permissions")
            .accessibilityHint("Moves to the next onboarding step")
        }
        .padding(32)
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
