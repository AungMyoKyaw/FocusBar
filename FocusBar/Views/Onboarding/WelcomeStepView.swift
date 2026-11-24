import SwiftUI
import AppKit

struct WelcomeStepView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            if let icon = NSApp.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 72, height: 72)
            } else {
                Image(systemName: "timer")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.accentColor)
            }

            Text("Welcome to FocusBar")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("A menu bar Pomodoro timer with Apple Reminders and streak tracking.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "timer", title: "Focus Timer", description: "Run Pomodoro and break cycles from your menu bar")
                FeatureRow(icon: "star.fill", title: "XP & Achievements", description: "Track progress across 30 levels and 20 milestones")
                FeatureRow(icon: "flame.fill", title: "Daily Streaks", description: "Hit your daily target with automatic weekly freezes")
                FeatureRow(icon: "checklist", title: "Apple Reminders", description: "Link sessions to tasks and log focus time")
            }
            .padding(.horizontal, 24)

            Spacer()

            OnboardingPrimaryButton(
                title: "Continue",
                accessibilityLabel: "Continue to permissions",
                accessibilityHint: "Moves to the next onboarding step",
                action: onContinue
            )
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
