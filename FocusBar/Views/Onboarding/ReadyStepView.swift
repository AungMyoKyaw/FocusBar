import SwiftUI

struct ReadyStepView: View {
    let notificationStatus: PermissionStatus
    let reminderStatus: PermissionStatus
    let onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("You're All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("FocusBar is ready to help you stay focused.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                SummaryRow(title: "Notifications", status: notificationStatus)
                SummaryRow(title: "Reminders", status: reminderStatus)
            }
            .padding(16)
            .background(.quaternary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 24)

            Text("You can change these anytime in System Settings.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            OnboardingPrimaryButton(
                title: "Get Started",
                accessibilityLabel: "Get started with FocusBar",
                accessibilityHint: "Closes onboarding and opens the app",
                action: onGetStarted
            )
        }
        .padding(32)
    }
}

private struct SummaryRow: View {
    let title: String
    let status: PermissionStatus

    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
            Spacer()
            PermissionStatusBadge(status: status)
        }
        .accessibilityElement(children: .combine)
    }
}
