import SwiftUI

struct TimeSlotCard: View {
    let slot: ScheduleSlot
    let supplements: [Supplement]
    let status: SlotStatus
    let supplementsTaken: Set<UUID>    // Which supplements are marked taken
    let supplementsSkipped: Set<UUID>  // Which supplements are marked skipped
    let onSupplementToggle: (UUID) -> Void  // Toggle individual supplement
    let onMarkAllTaken: () -> Void
    let onMarkAllSkipped: () -> Void
    let onUndo: () -> Void

    @State private var isExpanded = true

    private var allMarked: Bool {
        let allIds = Set(supplements.map { $0.id })
        return supplementsTaken.union(supplementsSkipped).isSuperset(of: allIds)
    }

    private var someMarked: Bool {
        !supplementsTaken.isEmpty || !supplementsSkipped.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Time Header
            HStack {
                Text(slot.displayTime)
                    .font(Theme.timeFont)
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                StatusBadge(status: status, takenCount: supplementsTaken.count, totalCount: supplements.count)
            }
            .padding(.bottom, Theme.spacingSM)

            Divider()
                .background(Theme.border)

            // Context
            Text(slot.context.displayName)
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
                .padding(.top, Theme.spacingMD)

            // Supplements with individual checkboxes
            VStack(alignment: .leading, spacing: Theme.spacingSM) {
                ForEach(supplements) { supplement in
                    SupplementRow(
                        supplement: supplement,
                        isTaken: supplementsTaken.contains(supplement.id),
                        isSkipped: supplementsSkipped.contains(supplement.id),
                        onToggle: { onSupplementToggle(supplement.id) }
                    )
                }
            }
            .padding(.top, Theme.spacingMD)

            // Explanation
            if !slot.explanation.isEmpty && isExpanded {
                Text(slot.explanation)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
                    .italic()
                    .padding(.top, Theme.spacingMD)
                    .lineSpacing(4)
            }

            // Action Buttons
            if status == .upcoming || status == .missed {
                HStack(spacing: Theme.spacingMD) {
                    Button(action: onMarkAllTaken) {
                        Text("Mark All as Taken")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button(action: onMarkAllSkipped) {
                        Text("Skip All")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.top, Theme.spacingLG)
            } else if status == .partial {
                // Partial status - show both options
                VStack(spacing: Theme.spacingSM) {
                    HStack(spacing: Theme.spacingMD) {
                        Button(action: onMarkAllTaken) {
                            Text("Mark Remaining")
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button(action: onUndo) {
                            Text("Undo All")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .padding(.top, Theme.spacingLG)
            } else if status == .taken || status == .skipped {
                Button(action: onUndo) {
                    Text("Undo")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.top, Theme.spacingMD)
            }
        }
        .padding(Theme.spacingLG)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusMD)
        .opacity(status == .taken || status == .skipped ? 0.6 : 1.0)
    }
}

struct StatusBadge: View {
    let status: SlotStatus
    let takenCount: Int
    let totalCount: Int

    init(status: SlotStatus, takenCount: Int = 0, totalCount: Int = 0) {
        self.status = status
        self.takenCount = takenCount
        self.totalCount = totalCount
    }

    var body: some View {
        HStack(spacing: Theme.spacingXS) {
            Circle()
                .fill(status == .taken ? status.color : Color.clear)
                .overlay(
                    Circle()
                        .stroke(status.color, lineWidth: 1.5)
                )
                .frame(width: 12, height: 12)
                .overlay {
                    if status == .taken {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    } else if status == .skipped {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(status.color)
                    } else if status == .partial {
                        // Partial indicator
                        Text("\(takenCount)")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(status.color)
                    }
                }

            if status == .partial && totalCount > 0 {
                Text("\(takenCount)/\(totalCount)")
                    .font(Theme.captionFont)
                    .tracking(1)
                    .foregroundColor(status.color)
            } else {
                Text(status.displayText)
                    .font(Theme.captionFont)
                    .tracking(1)
                    .foregroundColor(status.color)
            }
        }
    }
}

struct SupplementRow: View {
    let supplement: Supplement
    let isTaken: Bool
    let isSkipped: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Theme.spacingSM) {
                // Checkbox
                Image(systemName: isTaken ? "checkmark.circle.fill" : (isSkipped ? "xmark.circle" : "circle"))
                    .font(.system(size: 20))
                    .foregroundColor(isTaken ? Theme.success : (isSkipped ? Theme.textSecondary : Theme.textSecondary.opacity(0.5)))

                Text(supplement.name)
                    .font(Theme.bodyFont)
                    .foregroundColor(isTaken || isSkipped ? Theme.textSecondary : Theme.textPrimary)
                    .strikethrough(isTaken || isSkipped)

                if !supplement.displayDosage.isEmpty {
                    Text("(\(supplement.displayDosage))")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 16) {
            // Upcoming state
            TimeSlotCard(
                slot: ScheduleSlot(
                    time: "07:00",
                    context: .emptyStomach,
                    supplementIds: [],
                    explanation: "Iron absorbs best on an empty stomach."
                ),
                supplements: [
                    Supplement(name: "Iron", category: .mineral, dosage: 65, dosageUnit: "mg"),
                    Supplement(name: "Vitamin C", category: .vitaminWaterSoluble, dosage: 500, dosageUnit: "mg")
                ],
                status: .upcoming,
                supplementsTaken: [],
                supplementsSkipped: [],
                onSupplementToggle: { _ in },
                onMarkAllTaken: {},
                onMarkAllSkipped: {},
                onUndo: {}
            )

            // Partial state
            TimeSlotCard(
                slot: ScheduleSlot(
                    time: "12:00",
                    context: .withLunch,
                    supplementIds: [],
                    explanation: ""
                ),
                supplements: [
                    Supplement(name: "Vitamin D", category: .vitaminFatSoluble, dosage: 5000, dosageUnit: "IU"),
                    Supplement(name: "Omega-3", category: .omega, dosage: 1000, dosageUnit: "mg")
                ],
                status: .partial,
                supplementsTaken: [UUID()],  // One taken
                supplementsSkipped: [],
                onSupplementToggle: { _ in },
                onMarkAllTaken: {},
                onMarkAllSkipped: {},
                onUndo: {}
            )
        }
        .padding()
    }
}
