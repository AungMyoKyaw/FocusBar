import SwiftUI

struct PermissionsStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "shield.checkered")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)

            Text("Permissions")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("FocusBar works best with these permissions. You can change them later in System Settings.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 16) {
                PermissionCard(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "Get notified when sessions end",
                    status: viewModel.notificationStatus,
                    action: {
                        Task { await viewModel.requestNotificationPermission() }
                    }
                )

                PermissionCard(
                    icon: "checklist",
                    title: "Reminders",
                    description: "Link focus sessions to your tasks",
                    status: viewModel.reminderStatus,
                    action: {
                        Task { await viewModel.requestReminderPermission() }
                    },
                    skipAction: {
                        viewModel.skipReminders()
                    }
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityLabel("Continue to summary")
            .accessibilityHint("Moves to the final onboarding step")
        }
        .padding(32)
    }
}

private struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let status: PermissionStatus
    let action: () -> Void
    var skipAction: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            statusView
        }
        .padding(12)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var statusView: some View {
        switch status {
        case .unknown:
            HStack(spacing: 8) {
                if let skipAction {
                    Button("Skip", action: skipAction)
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                }
                Button("Enable", action: action)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityHint("Requests permission for \(title)")
            }
        case .granted:
            Label("Enabled", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
        case .denied:
            Label("Denied", systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.caption)
        case .skipped:
            Label("Skipped", systemImage: "minus.circle.fill")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }
}
