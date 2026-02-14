import SwiftUI

struct OnboardingContainerView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(\.dismiss) private var dismiss

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
