import Foundation
import SwiftData
import SwiftUI

/// Service for calculating streaks and historical completion data
struct StreakService {

    /// Calculate the current streak (consecutive days with ALL supplements taken)
    /// - Parameters:
    ///   - intakeLogs: All intake logs for the user
    ///   - slots: All schedule slots for the user
    ///   - supplements: All supplements for the user (optional, used to filter archived)
    /// - Returns: Number of consecutive complete days (not including today unless complete)
    static func calculateStreak(intakeLogs: [IntakeLog], slots: [ScheduleSlot], supplements: [Supplement] = []) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let allSlotIds = Set(slots.map { $0.id })
        let activeSupplements = supplements.filter { !$0.isArchived }

        var streak = 0
        var checkDate = calendar.date(byAdding: .day, value: -1, to: today)!

        // Check if today is complete - if so, include it in streak
        if isDayComplete(date: today, intakeLogs: intakeLogs, slots: slots, allSlotIds: allSlotIds, activeSupplements: activeSupplements) {
            streak = 1
        }

        // Count consecutive complete days going backwards
        while true {
            let normalizedCheckDate = calendar.startOfDay(for: checkDate)

            // Calculate active supplements for THIS specific date (respecting frequency AND creation date)
            let activeSlotsForDate = slots.filter { !$0.supplementIds.isEmpty && $0.isActiveOn(date: checkDate) }
            // Filter supplements: must be active AND must have existed on this date
            let activeSupplementCount: Int
            if supplements.isEmpty {
                activeSupplementCount = activeSlotsForDate.reduce(0) { $0 + $1.supplementIds.count }
            } else {
                activeSupplementCount = activeSlotsForDate.reduce(0) { sum, slot in
                    let supplementsExistingOnDate = slot.supplementIds.filter { id in
                        guard let supplement = activeSupplements.first(where: { $0.id == id }) else { return false }
                        return calendar.startOfDay(for: supplement.createdAt) <= normalizedCheckDate
                    }
                    return sum + supplementsExistingOnDate.count
                }
            }

            // Skip days with no active slots (don't break streak)
            if activeSupplementCount == 0 {
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                // Safety: don't go back more than 365 days
                if calendar.dateComponents([.day], from: checkDate, to: today).day ?? 0 > 365 { break }
                continue
            }

            let dateString = dateString(for: checkDate)
            let logsForDay = intakeLogs.filter { $0.date == dateString && allSlotIds.contains($0.scheduleSlotId) }

            // Count individual supplements taken
            let takenSupplementCount = logsForDay.reduce(0) { $0 + $1.supplementIdsTaken.count }

            // Day is complete if all active supplements for that day were taken
            if takenSupplementCount >= activeSupplementCount {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }

            // Safety: don't go back more than 365 days
            if calendar.dateComponents([.day], from: checkDate, to: today).day ?? 0 > 365 { break }
        }

        return streak
    }

    /// Get the last 7 days of completion data for visualization
    /// - Parameters:
    ///   - intakeLogs: All intake logs for the user
    ///   - slots: All schedule slots for the user
    ///   - supplements: All supplements for the user (optional, used to filter archived)
    /// - Returns: Array of 7 DayData objects, from 6 days ago to today
    static func getSevenDayHistory(intakeLogs: [IntakeLog], slots: [ScheduleSlot], supplements: [Supplement] = []) -> [DayData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let allSlotIds = Set(slots.map { $0.id })
        let activeSupplements = supplements.filter { !$0.isArchived }

        var days: [DayData] = []

        for daysAgo in (0...6).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
            let normalizedDate = calendar.startOfDay(for: date)

            // Calculate active supplements for THIS specific date (respecting frequency AND creation date)
            let activeSlotsForDate = slots.filter { !$0.supplementIds.isEmpty && $0.isActiveOn(date: date) }
            // Filter supplements: must be active (not archived) AND must have existed on this date
            let totalCount: Int
            if supplements.isEmpty {
                totalCount = activeSlotsForDate.reduce(0) { $0 + $1.supplementIds.count }
            } else {
                totalCount = activeSlotsForDate.reduce(0) { sum, slot in
                    let supplementsExistingOnDate = slot.supplementIds.filter { id in
                        guard let supplement = activeSupplements.first(where: { $0.id == id }) else { return false }
                        // Only count if supplement existed on this date
                        return calendar.startOfDay(for: supplement.createdAt) <= normalizedDate
                    }
                    return sum + supplementsExistingOnDate.count
                }
            }

            let dateStr = dateString(for: date)
            let logsForDay = intakeLogs.filter { $0.date == dateStr && allSlotIds.contains($0.scheduleSlotId) }

            // Count individual supplements taken
            let takenCount = logsForDay.reduce(0) { $0 + $1.supplementIdsTaken.count }

            let status: DayCompletionStatus
            let isToday = calendar.isDateInToday(date)

            if totalCount == 0 {
                status = isToday ? .today : .missed
            } else if isToday {
                if takenCount >= totalCount {
                    status = .complete
                } else if takenCount > 0 {
                    status = .today
                } else {
                    status = .today
                }
            } else {
                // Past day
                if takenCount >= totalCount {
                    status = .complete
                } else if takenCount > 0 {
                    status = .partial
                } else {
                    status = .missed
                }
            }

            days.append(DayData(
                date: date,
                status: status,
                takenCount: takenCount,
                totalCount: totalCount
            ))
        }

        return days
    }

    /// Check if a specific day is complete (all supplements taken)
    private static func isDayComplete(date: Date, intakeLogs: [IntakeLog], slots: [ScheduleSlot], allSlotIds: Set<UUID>, activeSupplements: [Supplement] = []) -> Bool {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)

        // Calculate active supplements for THIS specific date (respecting frequency AND creation date)
        let activeSlotsForDate = slots.filter { !$0.supplementIds.isEmpty && $0.isActiveOn(date: date) }
        // Filter supplements: must be active AND must have existed on this date
        let activeSupplementCount: Int
        if activeSupplements.isEmpty {
            activeSupplementCount = activeSlotsForDate.reduce(0) { $0 + $1.supplementIds.count }
        } else {
            activeSupplementCount = activeSlotsForDate.reduce(0) { sum, slot in
                let supplementsExistingOnDate = slot.supplementIds.filter { id in
                    guard let supplement = activeSupplements.first(where: { $0.id == id }) else { return false }
                    return calendar.startOfDay(for: supplement.createdAt) <= normalizedDate
                }
                return sum + supplementsExistingOnDate.count
            }
        }

        guard activeSupplementCount > 0 else { return false }

        let dateStr = dateString(for: date)
        let takenCount = intakeLogs
            .filter { $0.date == dateStr && allSlotIds.contains($0.scheduleSlotId) }
            .reduce(0) { $0 + $1.supplementIdsTaken.count }

        return takenCount >= activeSupplementCount
    }

    /// Get completion data for an entire month
    /// - Parameters:
    ///   - month: Any date within the target month
    ///   - intakeLogs: All intake logs for the user
    ///   - slots: All schedule slots for the user
    ///   - supplements: All supplements for the user (optional, used to filter archived)
    /// - Returns: Dictionary mapping dates to DayData for the entire month
    static func getMonthHistory(for month: Date, intakeLogs: [IntakeLog], slots: [ScheduleSlot], supplements: [Supplement] = [], trackingStartDate: Date? = nil) -> [Date: DayData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let allSlotIds = Set(slots.map { $0.id })
        let activeSupplements = supplements.filter { !$0.isArchived }

        // Get the range of days in the month
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let daysInMonth = calendar.dateComponents([.day], from: monthInterval.start, to: monthInterval.end).day else {
            return [:]
        }

        var monthData: [Date: DayData] = [:]

        for dayOffset in 0..<daysInMonth {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: monthInterval.start) else { continue }
            let normalizedDate = calendar.startOfDay(for: date)

            // Calculate active supplements for THIS specific date (respecting frequency AND creation date)
            let activeSlotsForDate = slots.filter { !$0.supplementIds.isEmpty && $0.isActiveOn(date: normalizedDate) }
            // Filter supplements: must be active (not archived) AND must have existed on this date
            let totalCount: Int
            if supplements.isEmpty {
                totalCount = activeSlotsForDate.reduce(0) { $0 + $1.supplementIds.count }
            } else {
                totalCount = activeSlotsForDate.reduce(0) { sum, slot in
                    let supplementsExistingOnDate = slot.supplementIds.filter { id in
                        guard let supplement = activeSupplements.first(where: { $0.id == id }) else { return false }
                        // Only count if supplement existed on this date
                        return calendar.startOfDay(for: supplement.createdAt) <= normalizedDate
                    }
                    return sum + supplementsExistingOnDate.count
                }
            }

            let dateStr = dateString(for: normalizedDate)
            let logsForDay = intakeLogs.filter { $0.date == dateStr && allSlotIds.contains($0.scheduleSlotId) }

            // Count individual supplements taken
            let takenCount = logsForDay.reduce(0) { $0 + $1.supplementIdsTaken.count }

            let status: DayCompletionStatus
            let isToday = calendar.isDateInToday(normalizedDate)
            let isFuture = normalizedDate > today
            let isBeforeTracking: Bool
            if let trackingStartDate = trackingStartDate {
                isBeforeTracking = normalizedDate < calendar.startOfDay(for: trackingStartDate)
            } else {
                isBeforeTracking = false
            }

            if isBeforeTracking {
                status = .future
            } else if totalCount == 0 {
                status = isFuture ? .future : (isToday ? .today : .missed)
            } else if isFuture {
                status = .future
            } else if isToday {
                if takenCount >= totalCount {
                    status = .complete
                } else {
                    status = .today
                }
            } else {
                // Past day
                if takenCount >= totalCount {
                    status = .complete
                } else if takenCount > 0 {
                    status = .partial
                } else {
                    status = .missed
                }
            }

            monthData[normalizedDate] = DayData(
                date: normalizedDate,
                status: status,
                takenCount: takenCount,
                totalCount: totalCount
            )
        }

        return monthData
    }

    /// Convert a Date to the string format used by IntakeLog ("yyyy-MM-dd")
    static func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
