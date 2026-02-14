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

            Button(action: onGetStarted) {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityLabel("Get started with FocusBar")
            .accessibilityHint("Closes onboarding and opens the app")
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
            statusLabel
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch status {
        case .granted:
            Label("Enabled", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .denied:
            Label("Denied", systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
        case .skipped:
            Label("Skipped", systemImage: "minus.circle.fill")
                .foregroundStyle(.secondary)
        case .unknown:
            Label("Not Set", systemImage: "questionmark.circle.fill")
                .foregroundStyle(.secondary)
        }
    }
}
