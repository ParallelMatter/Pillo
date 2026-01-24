import SwiftUI

struct WelcomeView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Spacer()

            // Logo / Title
            VStack(spacing: Theme.spacingLG) {
                Text(Constants.Copy.welcomeTitle)
                    .font(.system(size: 48, weight: .light, design: .default))
                    .tracking(8)
                    .foregroundColor(Theme.textPrimary)

                Text(Constants.Copy.welcomeSubtitle)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()
            Spacer()
            Spacer()

            // Get Started Button
            Button(action: {
                viewModel.nextStep()
            }) {
                Text(Constants.Copy.getStarted)
            }
            .buttonStyle(PrimaryButtonStyle())

            Spacer()
                .frame(height: Theme.spacingXXL)
        }
        .padding(.horizontal, Theme.spacingXL)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        WelcomeView(viewModel: OnboardingViewModel())
    }
}
