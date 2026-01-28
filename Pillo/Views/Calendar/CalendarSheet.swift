import SwiftUI
import SwiftData

struct CalendarSheet: View {
    let intakeLogs: [IntakeLog]
    let slots: [ScheduleSlot]
    let supplements: [Supplement]
    let trackingStartDate: Date

    @Environment(\.dismiss) private var dismiss
    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: Date? = nil
    @State private var selectedDayData: DayData? = nil
    @State private var showingDayDetail = false

    private var calendar: Calendar {
        Calendar.current
    }

    private var monthYearTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var monthData: [Date: DayData] {
        StreakService.getMonthHistory(for: displayedMonth, intakeLogs: intakeLogs, slots: slots, supplements: supplements, trackingStartDate: trackingStartDate)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: Theme.spacingLG) {
                    // Month navigation
                    HStack {
                        Button(action: {
                            withAnimation {
                                if let newMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
                                    displayedMonth = newMonth
                                }
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(canGoToPreviousMonth ? Theme.textPrimary : Theme.textSecondary.opacity(0.3))
                                .frame(width: 44, height: 44)
                        }
                        .disabled(!canGoToPreviousMonth)

                        Spacer()

                        Text(monthYearTitle)
                            .font(Theme.titleFont)
                            .foregroundColor(Theme.textPrimary)

                        Spacer()

                        Button(action: {
                            withAnimation {
                                if let newMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
                                    // Don't allow navigating to future months
                                    let now = Date()
                                    let currentMonth = calendar.dateComponents([.year, .month], from: now)
                                    let newMonthComponents = calendar.dateComponents([.year, .month], from: newMonth)
                                    if let currentYear = currentMonth.year, let currentM = currentMonth.month,
                                       let newYear = newMonthComponents.year, let newM = newMonthComponents.month {
                                        if newYear < currentYear || (newYear == currentYear && newM <= currentM) {
                                            displayedMonth = newMonth
                                        }
                                    }
                                }
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(canGoToNextMonth ? Theme.textPrimary : Theme.textSecondary.opacity(0.3))
                                .frame(width: 44, height: 44)
                        }
                        .disabled(!canGoToNextMonth)
                    }
                    .padding(.horizontal, Theme.spacingMD)

                    // Calendar
                    MonthCalendarView(
                        month: displayedMonth,
                        monthData: monthData,
                        onDaySelected: { date in
                            selectedDate = date
                            selectedDayData = monthData[date]
                            showingDayDetail = true
                        }
                    )
                    .padding(.horizontal, Theme.spacingMD)

                    Spacer()
                }
                .padding(.top, Theme.spacingLG)
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
            .sheet(isPresented: $showingDayDetail) {
                if let date = selectedDate, let dayData = selectedDayData {
                    DayDetailSheet(
                        date: date,
                        dayData: dayData,
                        intakeLogs: intakeLogs,
                        slots: slots,
                        supplements: supplements
                    )
                }
            }
        }
    }

    private var canGoToPreviousMonth: Bool {
        guard let prevMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) else {
            return false
        }
        let startComponents = calendar.dateComponents([.year, .month], from: trackingStartDate)
        let prevComponents = calendar.dateComponents([.year, .month], from: prevMonth)

        guard let startYear = startComponents.year, let startM = startComponents.month,
              let prevYear = prevComponents.year, let prevM = prevComponents.month else {
            return false
        }

        return prevYear > startYear || (prevYear == startYear && prevM >= startM)
    }

    private var canGoToNextMonth: Bool {
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) else {
            return false
        }
        let now = Date()
        let currentMonth = calendar.dateComponents([.year, .month], from: now)
        let nextMonthComponents = calendar.dateComponents([.year, .month], from: nextMonth)

        guard let currentYear = currentMonth.year, let currentM = currentMonth.month,
              let nextYear = nextMonthComponents.year, let nextM = nextMonthComponents.month else {
            return false
        }

        return nextYear < currentYear || (nextYear == currentYear && nextM <= currentM)
    }
}

#Preview {
    CalendarSheet(
        intakeLogs: [],
        slots: [],
        supplements: [],
        trackingStartDate: Date()
    )
    .preferredColorScheme(.dark)
}
