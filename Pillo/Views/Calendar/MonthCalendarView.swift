import SwiftUI

struct MonthCalendarView: View {
    let month: Date
    let monthData: [Date: DayData]
    let onDaySelected: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]

    private var calendar: Calendar {
        Calendar.current
    }

    /// Get the first day of the month
    private var firstDayOfMonth: Date {
        let components = calendar.dateComponents([.year, .month], from: month)
        return calendar.date(from: components) ?? month
    }

    /// Get the weekday index of the first day (0 = Sunday)
    private var firstWeekdayIndex: Int {
        calendar.component(.weekday, from: firstDayOfMonth) - 1
    }

    /// Get the number of days in the month
    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: month)?.count ?? 30
    }

    /// Generate all date cells including empty cells for padding
    private var calendarCells: [Date?] {
        var cells: [Date?] = []

        // Add empty cells for days before the first of the month
        for _ in 0..<firstWeekdayIndex {
            cells.append(nil)
        }

        // Add actual days of the month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                cells.append(calendar.startOfDay(for: date))
            }
        }

        return cells
    }

    var body: some View {
        VStack(spacing: Theme.spacingMD) {
            // Weekday headers
            HStack(spacing: 4) {
                ForEach(weekdaySymbols.indices, id: \.self) { index in
                    Text(weekdaySymbols[index])
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(calendarCells.indices, id: \.self) { index in
                    if let date = calendarCells[index] {
                        CalendarDayCell(
                            date: date,
                            dayData: monthData[date],
                            isSelected: false,
                            onTap: {
                                onDaySelected(date)
                            }
                        )
                    } else {
                        // Empty cell for padding
                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                }
            }
        }
    }
}

#Preview {
    MonthCalendarView(
        month: Date(),
        monthData: [:],
        onDaySelected: { _ in }
    )
    .padding()
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
