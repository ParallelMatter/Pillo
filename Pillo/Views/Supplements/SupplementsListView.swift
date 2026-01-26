import SwiftUI
import SwiftData

struct SupplementsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @Query private var supplements: [Supplement]
    @State private var viewModel = SupplementsViewModel()

    private var user: User? { users.first }
    private var slots: [ScheduleSlot] {
        user?.scheduleSlots ?? []
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.spacingLG) {
                        // Header
                        Text("MY ROUTINE")
                            .font(Theme.headerFont)
                            .tracking(2)
                            .foregroundColor(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Theme.spacingLG)
                            .padding(.top, Theme.spacingMD)

                        if let user = user {
                            // Grouped Supplements
                            GroupedSupplementsSection(
                                viewModel: viewModel,
                                supplements: supplements,
                                slots: slots,
                                user: user
                            )

                            // Add Button
                            Button(action: {
                                viewModel.showingAddSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Add to Routine")
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .padding(.horizontal, Theme.spacingLG)

                            // Interactions Section
                            InteractionsSection(
                                viewModel: viewModel,
                                supplements: supplements
                            )
                        }
                    }
                    .padding(.bottom, Theme.spacingXXL)
                }
            }
            .sheet(isPresented: $viewModel.showingAddSheet) {
                if let user = user {
                    AddSupplementSheet(viewModel: viewModel, user: user)
                }
            }
            .sheet(item: $viewModel.selectedSupplement) { supplement in
                if let user = user {
                    SupplementDetailSheet(
                        supplement: supplement,
                        viewModel: viewModel,
                        user: user
                    )
                }
            }
            .sheet(item: $viewModel.selectedReference) { reference in
                if let user = user {
                    SupplementReferenceDetailSheet(
                        reference: reference,
                        viewModel: viewModel,
                        user: user
                    )
                }
            }
        }
    }
}

struct GroupedSupplementsSection: View {
    @Bindable var viewModel: SupplementsViewModel
    let supplements: [Supplement]
    let slots: [ScheduleSlot]
    let user: User

    @State private var selectedSlotForEdit: ScheduleSlot?

    var body: some View {
        let groups = viewModel.groupSupplementsBySlotWithSlot(supplements: supplements, slots: slots)

        LazyVStack(spacing: Theme.spacingLG) {
            ForEach(groups, id: \.slot.id) { group in
                VStack(alignment: .leading, spacing: Theme.spacingSM) {
                    // Tappable slot header
                    Button(action: {
                        selectedSlotForEdit = group.slot
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(group.slot.displayTime) - \(group.slot.context.shortDisplayName)".uppercased())
                                    .font(Theme.headerFont)
                                    .tracking(1)
                                    .foregroundColor(Theme.textSecondary)

                                // Show frequency if not daily
                                if case .daily = group.slot.frequency {
                                    // Don't show anything for daily (default)
                                } else {
                                    Text(group.slot.frequency.displayName)
                                        .font(Theme.captionFont)
                                        .foregroundColor(Theme.accent)
                                }
                            }

                            Spacer()

                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                    .padding(.horizontal, Theme.spacingLG)

                    ForEach(group.supplements) { supplement in
                        Button(action: {
                            viewModel.selectedSupplement = supplement
                        }) {
                            HStack {
                                Text(supplement.name)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textPrimary)

                                Spacer()

                                Text(supplement.displayDosage)
                                    .font(Theme.captionFont)
                                    .foregroundColor(Theme.textSecondary)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .padding(Theme.spacingMD)
                            .background(Theme.surface)
                            .cornerRadius(Theme.cornerRadiusSM)
                        }
                        .padding(.horizontal, Theme.spacingLG)
                    }
                }
            }
        }
        .sheet(item: $selectedSlotForEdit) { slot in
            SlotEditSheet(slot: slot, user: user)
        }
    }
}

struct InteractionsSection: View {
    @Bindable var viewModel: SupplementsViewModel
    let supplements: [Supplement]

    var body: some View {
        let interactions = viewModel.getInteractionsForUserSupplements(supplements)

        if !interactions.isEmpty {
            VStack(alignment: .leading, spacing: Theme.spacingMD) {
                Divider()
                    .background(Theme.border)
                    .padding(.horizontal, Theme.spacingLG)
                    .padding(.top, Theme.spacingLG)

                Text("INTERACTIONS DETECTED")
                    .font(Theme.headerFont)
                    .tracking(1)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, Theme.spacingLG)

                ForEach(interactions, id: \.supplementA) { interaction in
                    HStack(alignment: .top, spacing: Theme.spacingSM) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Theme.warning)
                            .font(.system(size: 14))

                        VStack(alignment: .leading, spacing: Theme.spacingXS) {
                            Text("\(interaction.supplementA.capitalized) ↔ \(interaction.supplementB.capitalized)")
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textPrimary)

                            Text(interaction.description)
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                                .lineSpacing(2)
                        }
                    }
                    .padding(Theme.spacingMD)
                    .background(Theme.surface)
                    .cornerRadius(Theme.cornerRadiusSM)
                    .padding(.horizontal, Theme.spacingLG)
                }
            }
        }
    }
}

#Preview {
    SupplementsListView()
        .preferredColorScheme(.dark)
        .modelContainer(for: [User.self, Supplement.self, ScheduleSlot.self, IntakeLog.self], inMemory: true)
}
