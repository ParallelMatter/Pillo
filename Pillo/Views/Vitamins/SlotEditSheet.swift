import SwiftUI
import SwiftData

struct SlotEditSheet: View {
    let slot: ScheduleSlot
    let user: User
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var frequency: ScheduleFrequency

    init(slot: ScheduleSlot, user: User) {
        self.slot = slot
        self.user = user
        self._frequency = State(initialValue: slot.frequency)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.spacingLG) {
                        // Slot Info Header
                        VStack(alignment: .leading, spacing: Theme.spacingSM) {
                            Text(slot.displayTime)
                                .font(Theme.titleFont)
                                .foregroundColor(Theme.textPrimary)

                            Text(slot.context.displayName)
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textSecondary)
                        }

                        Divider()
                            .background(Theme.border)

                        // Frequency Section
                        VStack(alignment: .leading, spacing: Theme.spacingSM) {
                            Text("SCHEDULE")
                                .font(Theme.headerFont)
                                .tracking(1)
                                .foregroundColor(Theme.textSecondary)

                            ScheduleFrequencyPicker(frequency: $frequency)
                        }

                        // Current frequency display
                        Text("Currently: \(frequency.displayName)")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textSecondary)

                        Spacer(minLength: Theme.spacingXL)

                        // Save Button
                        Button(action: saveChanges) {
                            Text("Save Changes")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(Theme.spacingLG)
                }
            }
            .navigationTitle("Edit Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }

    private func saveChanges() {
        // Update the slot's frequency
        slot.frequency = frequency
        try? modelContext.save()

        // Reschedule notifications
        if user.notificationsEnabled {
            NotificationService.shared.scheduleNotifications(
                for: user.scheduleSlots ?? [],
                supplements: user.supplements ?? [],
                advanceMinutes: user.notificationAdvanceMinutes,
                sound: user.notificationSound
            )
        }

        dismiss()
    }
}

#Preview {
    let slot = ScheduleSlot(
        time: "08:00",
        context: .withBreakfast,
        supplementIds: [],
        explanation: "Test slot"
    )

    return SlotEditSheet(
        slot: slot,
        user: User(
            breakfastTime: "08:00",
            lunchTime: "12:30",
            dinnerTime: "19:00"
        )
    )
    .preferredColorScheme(.dark)
}
