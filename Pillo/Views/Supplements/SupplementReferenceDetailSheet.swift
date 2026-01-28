import SwiftUI
import SwiftData

struct SupplementReferenceDetailSheet: View {
    let reference: SupplementReference
    @Bindable var viewModel: SupplementsViewModel
    let user: User
    var onAdd: (() -> Void)?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showDuplicateAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.spacingLG) {
                        headerSection

                        Divider()
                            .background(Theme.border)

                        if !reference.benefits.isEmpty {
                            InfoSection(title: "WHY IT MATTERS", content: reference.benefits)
                        }

                        demographicsSection

                        if !reference.deficiencySigns.isEmpty {
                            DeficiencySignsSection(signs: reference.deficiencySigns)
                        }

                        if !reference.absorptionNotes.isEmpty {
                            InfoSection(title: "BEST TIME TO TAKE", content: reference.absorptionNotes)
                        }

                        avoidWithSection
                        pairsWithSection
                        goalsSection

                        Spacer(minLength: Theme.spacingXL)

                        addButton
                    }
                    .padding(Theme.spacingLG)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textPrimary)
                }
            }
            .alert("Already added", isPresented: $showDuplicateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This supplement is already in your routine.")
            }
        }
    }

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            Text(reference.primaryName.uppercased())
                .font(Theme.titleFont)
                .tracking(1)
                .foregroundColor(Theme.textPrimary)

            Text(reference.supplementCategory.displayName)
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textSecondary)

            Text("Typical dose: \(reference.displayDosageRange)")
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textSecondary)
        }
    }

    @ViewBuilder
    private var demographicsSection: some View {
        if !reference.demographics.isEmpty {
            VStack(alignment: .leading, spacing: Theme.spacingSM) {
                Text("ESPECIALLY HELPFUL FOR")
                    .font(Theme.headerFont)
                    .tracking(1)
                    .foregroundColor(Theme.textSecondary)

                ForEach(reference.demographics, id: \.self) { demographic in
                    HStack(alignment: .top, spacing: Theme.spacingSM) {
                        Text("\u{2022}")
                            .foregroundColor(Theme.accent)
                        Text(demographic)
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textPrimary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var avoidWithSection: some View {
        if !reference.avoidWith.isEmpty {
            VStack(alignment: .leading, spacing: Theme.spacingSM) {
                Text("WHAT TO AVOID")
                    .font(Theme.headerFont)
                    .tracking(1)
                    .foregroundColor(Theme.textSecondary)

                ForEach(reference.avoidWith, id: \.self) { avoid in
                    HStack(alignment: .top, spacing: Theme.spacingSM) {
                        Text("\u{2022}")
                            .foregroundColor(Theme.warning)
                        Text("Don't take with \(avoid.replacingOccurrences(of: "_", with: " ").capitalized)")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textPrimary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var pairsWithSection: some View {
        if !reference.pairsWith.isEmpty {
            VStack(alignment: .leading, spacing: Theme.spacingSM) {
                Text("PAIRS WELL WITH")
                    .font(Theme.headerFont)
                    .tracking(1)
                    .foregroundColor(Theme.textSecondary)

                ForEach(reference.pairsWith, id: \.self) { pair in
                    HStack(alignment: .top, spacing: Theme.spacingSM) {
                        Text("\u{2022}")
                            .foregroundColor(Theme.success)
                        Text(pair.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textPrimary)
                    }
                }

                let synergies = SupplementDatabaseService.shared.getSynergies(for: reference.id)
                ForEach(synergies, id: \.supplementA) { synergy in
                    Text(synergy.effect)
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textSecondary)
                        .italic()
                        .padding(.leading, Theme.spacingMD)
                }
            }
        }
    }

    @ViewBuilder
    private var goalsSection: some View {
        if !reference.goalRelevance.isEmpty {
            VStack(alignment: .leading, spacing: Theme.spacingSM) {
                Text("SUPPORTS")
                    .font(Theme.headerFont)
                    .tracking(1)
                    .foregroundColor(Theme.textSecondary)

                FlowLayout(spacing: Theme.spacingSM) {
                    ForEach(reference.goalRelevance, id: \.self) { goalString in
                        if let goal = Goal(rawValue: goalString) {
                            GoalTag(goal: goal)
                        }
                    }
                }
            }
        }
    }

    private var addButton: some View {
        Button(action: {
            let added = viewModel.addSupplement(
                from: reference,
                dosage: reference.defaultDosageMin,
                dosageUnit: reference.defaultDosageUnit,
                form: nil,
                to: user,
                modelContext: modelContext
            )
            if added {
                viewModel.searchQuery = ""
                dismiss()
                onAdd?()
            } else {
                showDuplicateAlert = true
            }
        }) {
            Text("Add to routine")
        }
        .buttonStyle(PrimaryButtonStyle())
    }
}
