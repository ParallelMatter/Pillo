import SwiftUI

struct StreakCard: View {
    let streak: Int
    let sevenDayHistory: [DayData]
    var onTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMD) {
            // Streak display
            HStack(spacing: Theme.spacingSM) {
                if streak > 0 {
                    Text("\(streak)")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.warning)

                    Text(streak == 1 ? "day streak" : "days streak")
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textSecondary)
                } else {
                    Text("Start your streak")
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                if streak > 0 {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.warning)
                }

                // Chevron indicator for tap
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
            }

            // 7-day dot visualization
            HStack(spacing: 0) {
                ForEach(sevenDayHistory) { day in
                    DayDot(day: day)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .cardStyle()
        .onTapGesture {
            onTap?()
        }
    }
}

struct DayDot: View {
    let day: DayData

    private var dotColor: Color {
        switch day.status {
        case .complete:
            return Theme.success
        case .partial:
            return Theme.success.opacity(0.5)
        case .missed:
            return Theme.border
        case .future, .today:
            return Theme.border
        }
    }

    private var showRing: Bool {
        day.isToday
    }

    var body: some View {
        VStack(spacing: Theme.spacingXS) {
            // Day letter
            Text(day.dayLetter)
                .font(Theme.captionFont)
                .foregroundColor(day.isToday ? Theme.textPrimary : Theme.textSecondary)

            // Dot
            ZStack {
                // Background ring for today
                if showRing {
                    Circle()
                        .stroke(Theme.textSecondary, lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                }

                // The dot itself
                Group {
                    switch day.status {
                    case .complete:
                        Circle()
                            .fill(Theme.success)
                            .frame(width: 16, height: 16)

                    case .partial:
                        // Half-filled circle
                        ZStack {
                            Circle()
                                .fill(Theme.border)
                                .frame(width: 16, height: 16)

                            Circle()
                                .trim(from: 0, to: 0.5)
                                .fill(Theme.success)
                                .frame(width: 16, height: 16)
                                .rotationEffect(.degrees(-90))
                        }

                    case .missed:
                        Circle()
                            .fill(Theme.border)
                            .frame(width: 16, height: 16)

                    case .future, .today:
                        if day.takenCount > 0 && day.takenCount < day.totalCount {
                            // Partial progress today
                            ZStack {
                                Circle()
                                    .fill(Theme.border)
                                    .frame(width: 16, height: 16)

                                Circle()
                                    .trim(from: 0, to: CGFloat(day.takenCount) / max(CGFloat(day.totalCount), 1))
                                    .stroke(Theme.success, lineWidth: 3)
                                    .frame(width: 13, height: 13)
                                    .rotationEffect(.degrees(-90))
                            }
                        } else if day.takenCount == day.totalCount && day.totalCount > 0 {
                            // Complete today
                            Circle()
                                .fill(Theme.success)
                                .frame(width: 16, height: 16)
                        } else {
                            // Empty/hollow
                            Circle()
                                .stroke(Theme.border, lineWidth: 2)
                                .frame(width: 14, height: 14)
                        }
                    }
                }
            }
            .frame(width: 24, height: 24)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // With streak
        StreakCard(
            streak: 7,
            sevenDayHistory: [
                DayData(date: Date().addingTimeInterval(-6*86400), status: .complete, takenCount: 3, totalCount: 3),
                DayData(date: Date().addingTimeInterval(-5*86400), status: .complete, takenCount: 3, totalCount: 3),
                DayData(date: Date().addingTimeInterval(-4*86400), status: .partial, takenCount: 2, totalCount: 3),
                DayData(date: Date().addingTimeInterval(-3*86400), status: .complete, takenCount: 3, totalCount: 3),
                DayData(date: Date().addingTimeInterval(-2*86400), status: .missed, takenCount: 0, totalCount: 3),
                DayData(date: Date().addingTimeInterval(-1*86400), status: .complete, takenCount: 3, totalCount: 3),
                DayData(date: Date(), status: .today, takenCount: 1, totalCount: 3)
            ]
        )

        // No streak
        StreakCard(
            streak: 0,
            sevenDayHistory: [
                DayData(date: Date().addingTimeInterval(-6*86400), status: .missed, takenCount: 0, totalCount: 3),
                DayData(date: Date().addingTimeInterval(-5*86400), status: .missed, takenCount: 0, totalCount: 3),
                DayData(date: Date().addingTimeInterval(-4*86400), status: .missed, takenCount: 0, totalCount: 3),
                DayData(date: Date().addingTimeInterval(-3*86400), status: .missed, takenCount: 0, totalCount: 3),
                DayData(date: Date().addingTimeInterval(-2*86400), status: .missed, takenCount: 0, totalCount: 3),
                DayData(date: Date().addingTimeInterval(-1*86400), status: .missed, takenCount: 0, totalCount: 3),
                DayData(date: Date(), status: .today, takenCount: 0, totalCount: 3)
            ]
        )
    }
    .padding()
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
