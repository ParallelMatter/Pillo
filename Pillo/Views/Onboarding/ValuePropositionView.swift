import SwiftUI

struct ValuePropositionView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var currentPage: Int = 0

    private let pages: [ValuePropPage] = [
        ValuePropPage(
            icon: "clock.arrow.2.circlepath",
            headline: Constants.Copy.valueProp1Headline,
            subtitle: Constants.Copy.valueProp1Subtitle
        ),
        ValuePropPage(
            icon: "arrow.triangle.branch",
            headline: Constants.Copy.valueProp2Headline,
            subtitle: Constants.Copy.valueProp2Subtitle
        ),
        ValuePropPage(
            icon: "link",
            headline: Constants.Copy.valueProp3Headline,
            subtitle: Constants.Copy.valueProp3Subtitle
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Spacer()

            // Paged content
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: Theme.spacingLG) {
                        Image(systemName: page.icon)
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(Theme.textSecondary)

                        Text(page.headline)
                            .font(Theme.displayFont)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Theme.textPrimary)
                            .lineSpacing(4)

                        Text(page.subtitle)
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, Theme.spacingXL)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            Spacer()
            Spacer()
            Spacer()

            // Custom page dots
            HStack(spacing: Theme.spacingSM) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Theme.textPrimary : Theme.textSecondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(Theme.springAnimation, value: currentPage)
                }
            }
            .padding(.bottom, Theme.spacingXL)

            // Button
            Button(action: {
                if currentPage < pages.count - 1 {
                    withAnimation(Theme.springAnimation) {
                        currentPage += 1
                    }
                } else {
                    viewModel.nextStep()
                }
            }) {
                Text(currentPage < pages.count - 1 ? "Next" : "Continue")
            }
            .buttonStyle(PrimaryButtonStyle())

            Spacer()
                .frame(height: Theme.spacingXXL)
        }
        .padding(.horizontal, Theme.spacingXL)
    }
}

private struct ValuePropPage {
    let icon: String
    let headline: String
    let subtitle: String
}

#Preview {
    ZStack {
        Color.white.ignoresSafeArea()
        ValuePropositionView(viewModel: OnboardingViewModel())
    }
}
