import SwiftUI
import SFSymbols

/// The onboarding step in the flow.
private enum OnboardingStep {
    case welcome
    case attitudeSelection
    case permissions
}

/// The onboarding flow for first-time users.
struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var viewModel = OnboardingViewModel()
    @State private var currentStep: OnboardingStep = .welcome

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            switch currentStep {
            case .welcome:
                welcomeContent

            case .attitudeSelection:
                attitudeSelectionContent

            case .permissions:
                permissionsContent
            }
        }
        .padding()
        .animation(.easeInOut, value: currentStep)
    }

    // MARK: - Private Views

    private var welcomeContent: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(symbol: .figureRun)
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("Welcome to Workout Buddy")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("Get personalized feedback after every workout")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button("Get Started") {
                currentStep = .attitudeSelection
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var attitudeSelectionContent: some View {
        VStack(spacing: 20) {
            Text("Choose Your Vibes")
                .font(.largeTitle.bold())

            Text("Select one or more - your buddy will mix it up!")
                .font(.title3)
                .foregroundStyle(.secondary)

            Spacer()

            WordCloudView(selectedAttitudes: $viewModel.selectedAttitudes)

            Spacer()

            Button("Continue") {
                viewModel.saveAttitudes()
                currentStep = .permissions
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.hasSelection)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var permissionsContent: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(symbol: .checkmarkShieldFill)
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("One More Thing")
                .font(.largeTitle.bold())

            Text("We need permission to read your workouts and send you notifications")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button("Allow & Continue") {
                Task { @MainActor in
                    await viewModel.requestPermissions()
                    viewModel.completeOnboarding()
                    onComplete()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
