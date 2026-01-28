import SwiftUI

struct RemindMeSheet: View {
    let slot: ScheduleSlot
    let supplements: [Supplement]
    let onSelectTime: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingTimePicker = false
    @State private var customTime = Date()
    @State private var confirmedCustomTime = false

    private var presetOptions: [(label: String, minutes: Int)] {
        [
            ("+15 min", 15),
            ("+30 min", 30),
            ("+1 hr", 60)
        ]
    }

    // Filter valid presets (must be before midnight)
    private var validPresets: [(label: String, date: Date)] {
        let calendar = Calendar.current
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: Date()) ?? Date()

        return presetOptions.compactMap { option in
            guard let targetDate = calendar.date(byAdding: .minute, value: option.minutes, to: Date()),
                  targetDate <= endOfDay else {
                return nil
            }
            return (option.label, targetDate)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: Theme.spacingLG) {
                    // Header
                    VStack(alignment: .leading, spacing: Theme.spacingSM) {
                        Text("REMIND ME")
                            .font(Theme.headerFont)
                            .tracking(1)
                            .foregroundColor(Theme.textSecondary)

                        Text(supplementNames)
                            .font(Theme.titleFont)
                            .foregroundColor(Theme.textPrimary)
                    }

                    Divider()
                        .background(Theme.border)

                    // Preset Options
                    VStack(spacing: Theme.spacingSM) {
                        ForEach(validPresets, id: \.label) { option in
                            Button {
                                onSelectTime(option.date)
                                dismiss()
                            } label: {
                                HStack {
                                    Text(option.label)
                                        .font(Theme.bodyFont)
                                        .foregroundColor(Theme.textPrimary)
                                    Spacer()
                                    Text(formatTime(option.date))
                                        .font(Theme.captionFont)
                                        .foregroundColor(Theme.textSecondary)
                                }
                                .padding(Theme.spacingMD)
                                .background(Theme.surface)
                                .cornerRadius(Theme.cornerRadiusSM)
                            }
                        }
                    }

                    // Pick Time Button
                    Button {
                        showingTimePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "clock")
                            Text("Pick a time")
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Spacer()
                }
                .padding(Theme.spacingLG)
            }
            .navigationTitle("Set Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }
            }
            .sheet(isPresented: $showingTimePicker, onDismiss: {
                if confirmedCustomTime {
                    confirmedCustomTime = false
                    onSelectTime(customTime)
                    dismiss()
                }
            }) {
                TimePickerSheet(
                    selectedTime: $customTime,
                    onConfirm: {
                        confirmedCustomTime = true
                        showingTimePicker = false
                    }
                )
            }
        }
        .presentationDetents([.medium])
    }

    private var supplementNames: String {
        let names = supplements.map { $0.name }
        if names.count == 1 {
            return names[0]
        } else if names.count == 2 {
            return "\(names[0]) & \(names[1])"
        } else {
            return "\(names[0]) + \(names.count - 1) more"
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
