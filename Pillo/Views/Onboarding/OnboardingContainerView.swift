import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            switch viewModel.currentStep {
            case .welcome:
                WelcomeView(viewModel: viewModel)
            case .addSupplements:
                AddSupplementsView(viewModel: viewModel)
            case .mealTimes:
                MealTimesView(viewModel: viewModel)
            case .goals:
                GoalsSelectionView(viewModel: viewModel)
            case .generating:
                GeneratingView(viewModel: viewModel, modelContext: modelContext)
            }
        }
    }
}

#Preview {
    OnboardingContainerView()
        .modelContainer(for: [User.self, Supplement.self, ScheduleSlot.self, IntakeLog.self], inMemory: true)
}
