import SwiftUI
import SwiftData

struct GoalsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    private var user: User? { users.first }

    private var selectedGoals: [Goal] {
        guard let user = user else { return [] }
        return user.goals.compactMap { Goal(rawValue: $0) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.spacingLG) {
                        // Header
                        Text("YOUR GOALS")
                            .font(Theme.headerFont)
                            .tracking(2)
                            .foregroundColor(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Theme.spacingLG)
                            .padding(.top, Theme.spacingMD)

                        // Selected Goals Tags
                        if !selectedGoals.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Theme.spacingSM) {
                                    ForEach(selectedGoals, id: \.self) { goal in
                                        GoalPill(goal: goal)
                                    }
                                }
                                .padding(.horizontal, Theme.spacingLG)
                            }
                        }

                        Divider()
                            .background(Theme.border)
                            .padding(.horizontal, Theme.spacingLG)

                        // Recommendations Section
                        Text("BASED ON YOUR GOALS")
                            .font(Theme.headerFont)
                            .tracking(1)
                            .foregroundColor(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Theme.spacingLG)

                        ForEach(selectedGoals, id: \.self) { goal in
                            GoalRecommendationCard(goal: goal, user: user)
                        }

                        if selectedGoals.isEmpty {
                            VStack(spacing: Theme.spacingMD) {
                                Image(systemName: "target")
                                    .font(.system(size: 40))
                                    .foregroundColor(Theme.textSecondary.opacity(0.5))

                                Text("No goals selected")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textSecondary)

                                Text("Add goals to get personalized recommendations")
                                    .font(Theme.captionFont)
                                    .foregroundColor(Theme.textSecondary.opacity(0.7))
                            }
                            .padding(.top, Theme.spacingXXL)
                        }

                        // Disclaimer
                        DisclaimerCard()
                            .padding(.horizontal, Theme.spacingLG)

                        // Edit Goals Button
                        NavigationLink(destination: EditGoalsView(user: user)) {
                            Text("Edit goals")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .padding(.horizontal, Theme.spacingLG)
                        .padding(.bottom, Theme.spacingXXL)
                    }
                }
            }
        }
    }
}

struct GoalPill: View {
    let goal: Goal

    var body: some View {
        HStack(spacing: Theme.spacingXS) {
            Image(systemName: goal.icon)
                .font(.system(size: 12))
            Text(goal.displayName)
                .font(Theme.captionFont)
        }
        .foregroundColor(Theme.textPrimary)
        .padding(.horizontal, Theme.spacingMD)
        .padding(.vertical, Theme.spacingSM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusLG)
    }
}

struct GoalRecommendationCard: View {
    let goal: Goal
    let user: User?
    @Environment(\.modelContext) private var modelContext

    private var recommendations: [SupplementReference] {
        SupplementDatabaseService.shared.getSupplementsForGoal(goal)
    }

    private var userSupplementNames: [String] {
        (user?.supplements ?? []).map { $0.name.lowercased() }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMD) {
            HStack {
                Image(systemName: goal.icon)
                    .foregroundColor(Theme.textPrimary)

                Text("For \(goal.displayName.lowercased())")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textPrimary)
            }

            // Already taking
            let taking = recommendations.filter { ref in
                userSupplementNames.contains(ref.primaryName.lowercased())
            }

            if !taking.isEmpty {
                VStack(alignment: .leading, spacing: Theme.spacingSM) {
                    ForEach(taking) { ref in
                        HStack(spacing: Theme.spacingSM) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Theme.success)
                                .font(.system(size: 14))

                            Text(ref.primaryName)
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textPrimary)
                        }
                    }
                }
            }

            // Consider adding
            let notTaking = recommendations.filter { ref in
                !userSupplementNames.contains(ref.primaryName.lowercased())
            }.prefix(3)

            if !notTaking.isEmpty {
                Text("Consider adding:")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.top, Theme.spacingXS)

                VStack(alignment: .leading, spacing: Theme.spacingSM) {
                    ForEach(Array(notTaking)) { ref in
                        HStack {
                            Text(ref.primaryName)
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textSecondary)

                            Spacer()

                            Button(action: {
                                addSupplement(ref)
                            }) {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(Theme.textPrimary)
                            }
                        }
                    }
                }
            }
        }
        .cardStyle()
        .padding(.horizontal, Theme.spacingLG)
    }

    private func addSupplement(_ ref: SupplementReference) {
        guard let user = user else { return }
        let viewModel = SupplementsViewModel()
        _ = viewModel.addSupplement(
            from: ref,
            dosage: ref.defaultDosageMin,
            dosageUnit: ref.defaultDosageUnit,
            to: user,
            modelContext: modelContext
        )
    }
}

struct DisclaimerCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack(spacing: Theme.spacingSM) {
                Image(systemName: "info.circle")
                    .foregroundColor(Theme.textSecondary)
                    .font(.system(size: 14))

                Text("Disclaimer")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
            }

            Text("These are general wellness suggestions, not medical advice. Always consult your healthcare provider before starting new supplements.")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
                .lineSpacing(2)
        }
        .padding(Theme.spacingMD)
        .background(Theme.surface.opacity(0.5))
        .cornerRadius(Theme.cornerRadiusSM)
    }
}

struct EditGoalsView: View {
    let user: User?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedGoals: Set<Goal> = []

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: Theme.spacingLG) {
                // Goals Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: Theme.spacingMD) {
                        ForEach(Goal.allCases, id: \.self) { goal in
                            GoalCard(
                                goal: goal,
                                isSelected: selectedGoals.contains(goal),
                                action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        if selectedGoals.contains(goal) {
                                            selectedGoals.remove(goal)
                                        } else {
                                            selectedGoals.insert(goal)
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, Theme.spacingLG)
                }

                // Save Button
                Button(action: {
                    saveGoals()
                    dismiss()
                }) {
                    Text("Save")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Theme.spacingLG)
                .padding(.bottom, Theme.spacingXL)
            }
        }
        .navigationTitle("Edit Goals")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let user = user {
                selectedGoals = Set(user.goals.compactMap { Goal(rawValue: $0) })
            }
        }
    }

    private func saveGoals() {
        guard let user = user else { return }
        user.goals = selectedGoals.map { $0.rawValue }
        try? modelContext.save()
    }
}

#Preview {
    GoalsListView()
        .preferredColorScheme(.dark)
        .modelContainer(for: [User.self, Supplement.self, ScheduleSlot.self, IntakeLog.self], inMemory: true)
}
