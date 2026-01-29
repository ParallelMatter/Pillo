import SwiftUI

struct CalendarDayCell: View {
    let date: Date
    let dayData: DayData?
    let isSelected: Bool
    let trackingStartDate: Date?
    let onTap: () -> Void

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    /// Date is not trackable if it's in the future OR before the user started tracking
    private var isNotTrackable: Bool {
        let isFutureDate = date > Calendar.current.startOfDay(for: Date())
        if let startDate = trackingStartDate {
            let isBeforeTracking = date < Calendar.current.startOfDay(for: startDate)
            return isFutureDate || isBeforeTracking
        }
        return isFutureDate
    }

    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }

    var body: some View {
        Button(action: {
            if !isNotTrackable {
                onTap()
            }
        }) {
            ZStack {
                // Background circle with status color
                if let data = dayData {
                    switch data.status {
                    case .complete:
                        Circle()
                            .fill(Theme.success)
                            .frame(width: 36, height: 36)

                    case .partial:
                        ZStack {
                            Circle()
                                .fill(Theme.border)
                                .frame(width: 36, height: 36)
                            Circle()
                                .trim(from: 0, to: 0.5)
                                .fill(Theme.success)
                                .frame(width: 36, height: 36)
                                .rotationEffect(.degrees(-90))
                        }

                    case .missed:
                        Circle()
                            .fill(Theme.border)
                            .frame(width: 36, height: 36)

                    case .today:
                        if data.takenCount > 0 && data.takenCount < data.totalCount {
                            // Partial progress today
                            ZStack {
                                Circle()
                                    .fill(Theme.border)
                                    .frame(width: 36, height: 36)
                                Circle()
                                    .trim(from: 0, to: CGFloat(data.takenCount) / max(CGFloat(data.totalCount), 1))
                                    .stroke(Theme.success, lineWidth: 4)
                                    .frame(width: 32, height: 32)
                                    .rotationEffect(.degrees(-90))
                            }
                        } else if data.takenCount == data.totalCount && data.totalCount > 0 {
                            Circle()
                                .fill(Theme.success)
                                .frame(width: 36, height: 36)
                        } else {
                            Circle()
                                .stroke(Theme.border, lineWidth: 2)
                                .frame(width: 36, height: 36)
                        }

                    case .future:
                        Circle()
                            .stroke(Theme.border.opacity(0.5), lineWidth: 1)
                            .frame(width: 36, height: 36)
                    }
                } else {
                    // No data - hollow circle
                    Circle()
                        .stroke(Theme.border.opacity(0.3), lineWidth: 1)
                        .frame(width: 36, height: 36)
                }

                // Today ring indicator
                if isToday {
                    Circle()
                        .stroke(Theme.textPrimary, lineWidth: 2)
                        .frame(width: 42, height: 42)
                }

                // Day number
                Text("\(dayNumber)")
                    .font(Theme.bodyFont)
                    .foregroundColor(isNotTrackable ? Theme.textSecondary.opacity(0.5) : Theme.textPrimary)
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .disabled(isNotTrackable)
    }
}

#Preview {
    HStack(spacing: 8) {
        CalendarDayCell(
            date: Date(),
            dayData: DayData(date: Date(), status: .today, takenCount: 1, totalCount: 3),
            isSelected: false,
            trackingStartDate: Date().addingTimeInterval(-7*86400),
            onTap: {}
        )

        CalendarDayCell(
            date: Date().addingTimeInterval(-86400),
            dayData: DayData(date: Date().addingTimeInterval(-86400), status: .complete, takenCount: 3, totalCount: 3),
            isSelected: false,
            trackingStartDate: Date().addingTimeInterval(-7*86400),
            onTap: {}
        )

        CalendarDayCell(
            date: Date().addingTimeInterval(-2*86400),
            dayData: DayData(date: Date().addingTimeInterval(-2*86400), status: .partial, takenCount: 2, totalCount: 3),
            isSelected: false,
            trackingStartDate: Date().addingTimeInterval(-7*86400),
            onTap: {}
        )

        CalendarDayCell(
            date: Date().addingTimeInterval(-3*86400),
            dayData: DayData(date: Date().addingTimeInterval(-3*86400), status: .missed, takenCount: 0, totalCount: 3),
            isSelected: false,
            trackingStartDate: Date().addingTimeInterval(-7*86400),
            onTap: {}
        )
    }
    .padding()
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
