import SwiftUI

struct OnboardingContainerView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(\.dismiss) private var dismiss
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            stepIndicator
                .padding(.top, 16)

            switch viewModel.currentStep {
            case .welcome:
                WelcomeStepView(onContinue: { viewModel.advanceToNext() })
            case .permissions:
                PermissionsStepView(viewModel: viewModel, onContinue: { viewModel.advanceToNext() })
            case .ready:
                ReadyStepView(
                    notificationStatus: viewModel.notificationStatus,
                    reminderStatus: viewModel.reminderStatus,
                    onGetStarted: {
                        viewModel.completeOnboarding()
                        onDismiss?()
                        dismiss()
                    }
                )
            }
        }
        .frame(width: 480, height: 560)
        .animation(.easeInOut, value: viewModel.currentStep)
    }

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                Capsule()
                    .fill(step.rawValue <= viewModel.currentStep.rawValue ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 32)
    }
}

struct OnboardingPrimaryButton: View {
    let title: String
    let accessibilityLabel: String
    let accessibilityHint: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
}

struct PermissionStatusBadge: View {
    let status: PermissionStatus

    var body: some View {
        switch status {
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
        case .unknown:
            Label("Not Set", systemImage: "questionmark.circle.fill")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }
}
