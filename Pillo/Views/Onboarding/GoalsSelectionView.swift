import SwiftUI

struct GoalsSelectionView: View {
    @Bindable var viewModel: OnboardingViewModel

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Back Button
            HStack {
                Button(action: {
                    viewModel.previousStep()
                }) {
                    HStack(spacing: Theme.spacingXS) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("Back")
                            .font(Theme.labelFont)
                    }
                    .foregroundColor(Theme.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, Theme.spacingLG)
            .padding(.top, Theme.spacingMD)

            // Header
            VStack(spacing: Theme.spacingSM) {
                Text(Constants.Copy.goalsTitle)
                    .font(Theme.headerFont)
                    .tracking(2)
                    .foregroundColor(Theme.textPrimary)

                Text(Constants.Copy.goalsSubtitle)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.top, Theme.spacingMD)
            .padding(.bottom, Theme.spacingLG)

            // Goals Grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: Theme.spacingMD) {
                    ForEach(Goal.allCases, id: \.self) { goal in
                        GoalCard(
                            goal: goal,
                            isSelected: viewModel.selectedGoals.contains(goal),
                            action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.toggleGoal(goal)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, Theme.spacingLG)
            }

            Spacer()

            // Bottom Buttons
            VStack(spacing: Theme.spacingMD) {
                Button(action: {
                    viewModel.nextStep()
                }) {
                    Text("Generate my schedule")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button(action: {
                    viewModel.selectedGoals.removeAll()
                    viewModel.nextStep()
                }) {
                    Text("Skip for now")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, Theme.spacingLG)
            .padding(.bottom, Theme.spacingXL)
        }
    }
}

struct GoalCard: View {
    let goal: Goal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.spacingSM) {
                Image(systemName: goal.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Theme.textPrimary : Theme.textSecondary)

                Text(goal.displayName)
                    .font(Theme.captionFont)
                    .foregroundColor(isSelected ? Theme.textPrimary : Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spacingLG)
            .background(isSelected ? Theme.surface : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                    .stroke(isSelected ? Theme.textPrimary : Theme.border, lineWidth: 1)
            )
            .cornerRadius(Theme.cornerRadiusMD)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        GoalsSelectionView(viewModel: OnboardingViewModel())
    }
}
