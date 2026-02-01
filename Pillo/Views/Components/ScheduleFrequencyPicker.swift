import SwiftUI

struct ScheduleFrequencyPicker: View {
    @Binding var frequency: ScheduleFrequency

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMD) {
            // Frequency type selector
            FrequencyTypeRow(frequency: $frequency)

            // Additional options based on frequency type
            switch frequency {
            case .daily:
                EmptyView()

            case .specificDays(let days):
                DaySelector(
                    selectedDays: Binding(
                        get: { days },
                        set: { frequency = .specificDays($0) }
                    )
                )

            case .everyNDays(let interval, let startDate):
                IntervalSelector(
                    interval: Binding(
                        get: { interval },
                        set: { frequency = .everyNDays(interval: $0, startDate: startDate) }
                    )
                )

            case .weekly(let day):
                WeeklyDaySelector(
                    selectedDay: Binding(
                        get: { day },
                        set: { frequency = .weekly($0) }
                    )
                )
            }
        }
    }
}

// MARK: - Frequency Type Row

private struct FrequencyTypeRow: View {
    @Binding var frequency: ScheduleFrequency

    private var frequencyType: FrequencyType {
        switch frequency {
        case .daily: return .daily
        case .specificDays: return .specificDays
        case .everyNDays: return .everyNDays
        case .weekly: return .weekly
        }
    }

    var body: some View {
        HStack {
            Text("Repeat")
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Picker("", selection: Binding(
                get: { frequencyType },
                set: { newType in
                    switch newType {
                    case .daily:
                        frequency = .daily
                    case .specificDays:
                        frequency = .specificDays([.monday, .tuesday, .wednesday, .thursday, .friday])
                    case .everyNDays:
                        frequency = .everyNDays(interval: 2, startDate: Date())
                    case .weekly:
                        frequency = .weekly(.monday)
                    }
                }
            )) {
                ForEach(FrequencyType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.textSecondary)
        }
        .frame(height: Theme.fieldHeight)
        .padding(.horizontal, Theme.spacingMD)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusMD)
    }
}

private enum FrequencyType: CaseIterable {
    case daily
    case specificDays
    case everyNDays
    case weekly

    var displayName: String {
        switch self {
        case .daily: return "Every day"
        case .specificDays: return "Specific days"
        case .everyNDays: return "Every X days"
        case .weekly: return "Weekly"
        }
    }
}

// MARK: - Day Selector

struct DaySelector: View {
    @Binding var selectedDays: Set<ScheduleFrequency.Weekday>

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            Text("DAYS")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
                .tracking(1)

            HStack(spacing: Theme.spacingXS) {
                ForEach(ScheduleFrequency.Weekday.allCases) { day in
                    DayButton(
                        day: day,
                        isSelected: selectedDays.contains(day)
                    ) {
                        if selectedDays.contains(day) {
                            // Don't allow deselecting if it's the only one
                            if selectedDays.count > 1 {
                                selectedDays.remove(day)
                            }
                        } else {
                            selectedDays.insert(day)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, Theme.spacingMD)
    }
}

private struct DayButton: View {
    let day: ScheduleFrequency.Weekday
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            Text(day.initial)
                .font(Theme.labelFont)
                .fontWeight(.medium)
                .frame(width: 40, height: 40)
                .background(isSelected ? Theme.accent : Theme.surface)
                .foregroundColor(isSelected ? .white : Theme.textPrimary)
                .cornerRadius(20)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Theme.accent : Theme.border, lineWidth: 1)
                )
        }
    }
}

// MARK: - Interval Selector

private struct IntervalSelector: View {
    @Binding var interval: Int

    var body: some View {
        HStack {
            Text("Every")
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textPrimary)

            Picker("", selection: $interval) {
                ForEach(2...14, id: \.self) { n in
                    Text("\(n)").tag(n)
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.accent)

            Text("days")
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textPrimary)

            Spacer()
        }
        .padding(Theme.spacingMD)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusMD)
    }
}

// MARK: - Weekly Day Selector

private struct WeeklyDaySelector: View {
    @Binding var selectedDay: ScheduleFrequency.Weekday

    var body: some View {
        HStack {
            Text("On")
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Picker("", selection: $selectedDay) {
                ForEach(ScheduleFrequency.Weekday.allCases) { day in
                    Text(day.fullName).tag(day)
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.textSecondary)
        }
        .padding(Theme.spacingMD)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusMD)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()

        VStack(spacing: Theme.spacingLG) {
            ScheduleFrequencyPicker(frequency: .constant(.daily))
            ScheduleFrequencyPicker(frequency: .constant(.specificDays([.monday, .wednesday, .friday])))
            ScheduleFrequencyPicker(frequency: .constant(.everyNDays(interval: 3, startDate: Date())))
            ScheduleFrequencyPicker(frequency: .constant(.weekly(.sunday)))
        }
        .padding()
    }
}
