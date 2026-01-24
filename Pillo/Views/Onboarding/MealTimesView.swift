import SwiftUI

struct MealTimesView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: Theme.spacingSM) {
                Text(Constants.Copy.mealTimesTitle)
                    .font(Theme.headerFont)
                    .tracking(2)
                    .foregroundColor(Theme.textPrimary)

                Text(Constants.Copy.mealTimesSubtitle)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.top, Theme.spacingXL)
            .padding(.bottom, Theme.spacingXL)

            Spacer()

            // Time Pickers
            VStack(spacing: Theme.spacingXL) {
                if !viewModel.skipBreakfast {
                    MealTimePicker(
                        title: "BREAKFAST",
                        time: $viewModel.breakfastTime
                    )
                }

                MealTimePicker(
                    title: "LUNCH",
                    time: $viewModel.lunchTime
                )

                MealTimePicker(
                    title: "DINNER",
                    time: $viewModel.dinnerTime
                )
            }
            .padding(.horizontal, Theme.spacingXL)

            Spacer()

            // Skip Breakfast Toggle
            HStack {
                Text("I skip breakfast sometimes")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textSecondary)

                Spacer()

                Toggle("", isOn: $viewModel.skipBreakfast)
                    .tint(Theme.success)
                    .labelsHidden()
            }
            .padding(.horizontal, Theme.spacingLG)
            .padding(.vertical, Theme.spacingMD)
            .background(Theme.surface)
            .cornerRadius(Theme.cornerRadiusMD)
            .padding(.horizontal, Theme.spacingLG)

            Spacer()

            // Continue Button
            Button(action: {
                viewModel.nextStep()
            }) {
                Text("Continue")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Theme.spacingLG)
            .padding(.bottom, Theme.spacingXL)
        }
    }
}

struct MealTimePicker: View {
    let title: String
    @Binding var time: Date
    private let themeManager = ThemeManager.shared

    var body: some View {
        VStack(alignment: .center, spacing: Theme.spacingSM) {
            Text(title)
                .font(Theme.headerFont)
                .tracking(2)
                .foregroundColor(Theme.textSecondary)

            DatePicker(
                "",
                selection: $time,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .colorScheme(themeManager.themeMode.colorScheme)
            .frame(height: 100)
            .clipped()
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        MealTimesView(viewModel: OnboardingViewModel())
    }
}
