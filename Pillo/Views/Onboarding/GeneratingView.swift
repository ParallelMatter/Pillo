import SwiftUI
import SwiftData

struct GeneratingView: View {
    @Bindable var viewModel: OnboardingViewModel
    let modelContext: ModelContext

    @State private var animationPhase = 0

    var body: some View {
        VStack(spacing: Theme.spacingXL) {
            Spacer()

            // Animated Circle
            ZStack {
                Circle()
                    .stroke(Theme.border, lineWidth: 2)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Theme.textPrimary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(Double(animationPhase) * 360))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: animationPhase)
            }

            // Progress Text
            Text(viewModel.generationProgress)
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textSecondary)
                .animation(.easeInOut, value: viewModel.generationProgress)

            Spacer()
        }
        .onAppear {
            animationPhase = 1
            Task {
                await viewModel.generateSchedule(modelContext: modelContext)
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, Supplement.self, ScheduleSlot.self, IntakeLog.self, configurations: config)

    return ZStack {
        Color.black.ignoresSafeArea()
        GeneratingView(viewModel: OnboardingViewModel(), modelContext: container.mainContext)
    }
}
