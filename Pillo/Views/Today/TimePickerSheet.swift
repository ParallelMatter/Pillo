import SwiftUI

struct TimePickerSheet: View {
    @Binding var selectedTime: Date
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    // Time range: now to 11:59 PM
    private var minTime: Date { Date() }
    private var maxTime: Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: Date()) ?? Date()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: Theme.spacingLG) {
                    DatePicker(
                        "Select Time",
                        selection: $selectedTime,
                        in: minTime...maxTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()

                    Button(action: onConfirm) {
                        Text("Set reminder")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(Theme.spacingLG)
            }
            .navigationTitle("Pick Time")
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
        .presentationDetents([.medium])
        .onAppear {
            // Initialize to 30 minutes from now if not set
            let thirtyMinFromNow = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
            if selectedTime < minTime {
                selectedTime = min(thirtyMinFromNow, maxTime)
            }
        }
    }
}
