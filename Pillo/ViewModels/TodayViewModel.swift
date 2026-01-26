import Foundation
import SwiftUI
import SwiftData

@Observable
class TodayViewModel {
    var selectedSlotId: UUID?

    private let notificationService = NotificationService.shared

    func getSlotStatus(slot: ScheduleSlot, supplements: [Supplement], logs: [IntakeLog]) -> SlotStatus {
        let todayString = IntakeLog.todayDateString()

        // Use filtered supplement IDs (excludes archived/deleted supplements)
        let slotSupplementIds = Set(supplements.map { $0.id })

        if let log = logs.first(where: { $0.scheduleSlotId == slot.id && $0.date == todayString }) {
            let takenIds = Set(log.supplementIdsTaken)
            let skippedIds = Set(log.supplementIdsSkipped)

            // All supplements taken
            if takenIds.isSuperset(of: slotSupplementIds) && !slotSupplementIds.isEmpty {
                return .taken
            }

            // All supplements skipped
            if skippedIds.isSuperset(of: slotSupplementIds) && !slotSupplementIds.isEmpty {
                return .skipped
            }

            // All supplements have some action (mix of taken/skipped counts as complete)
            let allMarkedIds = takenIds.union(skippedIds)
            if allMarkedIds.isSuperset(of: slotSupplementIds) && !slotSupplementIds.isEmpty {
                return .taken
            }

            // Some supplements taken or skipped (partial)
            let hasAnyAction = !takenIds.intersection(slotSupplementIds).isEmpty ||
                              !skippedIds.intersection(slotSupplementIds).isEmpty
            if hasAnyAction {
                return .partial
            }

            // Check if rescheduled to a future time
            if let rescheduledTime = log.rescheduledTime, rescheduledTime > Date() {
                return .upcoming  // Treat as upcoming if reminder is pending
            }
        }

        // Check if the slot time has passed
        if let slotTime = slot.timeAsDate {
            if slotTime < Date() {
                return .missed
            }
        }

        return .upcoming
    }

    /// Check if a specific supplement is taken in a slot for today
    func isSupplementTaken(supplementId: UUID, slot: ScheduleSlot, logs: [IntakeLog]) -> Bool {
        let todayString = IntakeLog.todayDateString()
        guard let log = logs.first(where: { $0.scheduleSlotId == slot.id && $0.date == todayString }) else {
            return false
        }
        return log.supplementIdsTaken.contains(supplementId)
    }

    /// Check if a specific supplement is skipped in a slot for today
    func isSupplementSkipped(supplementId: UUID, slot: ScheduleSlot, logs: [IntakeLog]) -> Bool {
        let todayString = IntakeLog.todayDateString()
        guard let log = logs.first(where: { $0.scheduleSlotId == slot.id && $0.date == todayString }) else {
            return false
        }
        return log.supplementIdsSkipped.contains(supplementId)
    }

    // MARK: - Per-Supplement Actions

    /// Mark a single supplement as taken
    func markSupplementAsTaken(supplementId: UUID, slot: ScheduleSlot, modelContext: ModelContext, user: User) {
        let todayString = IntakeLog.todayDateString()
        let log = getOrCreateLog(for: slot, date: todayString, user: user, modelContext: modelContext)

        // Add to taken, remove from skipped if present
        if !log.supplementIdsTaken.contains(supplementId) {
            log.supplementIdsTaken.append(supplementId)
        }
        log.supplementIdsSkipped.removeAll { $0 == supplementId }
        log.takenAt = Date()

        try? modelContext.save()

        // Cancel notification if ALL supplements in slot are now taken
        let slotSupplementIds = Set(slot.supplementIds)
        let takenIds = Set(log.supplementIdsTaken)
        if takenIds.isSuperset(of: slotSupplementIds) && !slotSupplementIds.isEmpty {
            notificationService.cancelNotificationsForSlot(slot)
        }
    }

    /// Mark a single supplement as skipped
    func markSupplementAsSkipped(supplementId: UUID, slot: ScheduleSlot, modelContext: ModelContext, user: User) {
        let todayString = IntakeLog.todayDateString()
        let log = getOrCreateLog(for: slot, date: todayString, user: user, modelContext: modelContext)

        // Add to skipped, remove from taken if present
        if !log.supplementIdsSkipped.contains(supplementId) {
            log.supplementIdsSkipped.append(supplementId)
        }
        log.supplementIdsTaken.removeAll { $0 == supplementId }

        try? modelContext.save()
    }

    /// Undo status for a single supplement
    func undoSupplementStatus(supplementId: UUID, slot: ScheduleSlot, modelContext: ModelContext, user: User) {
        let todayString = IntakeLog.todayDateString()
        guard let log = (user.intakeLogs ?? []).first(where: { $0.scheduleSlotId == slot.id && $0.date == todayString }) else {
            return
        }

        log.supplementIdsTaken.removeAll { $0 == supplementId }
        log.supplementIdsSkipped.removeAll { $0 == supplementId }

        // If no supplements remain in the log, delete it
        if log.supplementIdsTaken.isEmpty && log.supplementIdsSkipped.isEmpty {
            modelContext.delete(log)
        }

        try? modelContext.save()
    }

    // MARK: - Slot-Level Actions (for "Mark All" convenience)

    /// Mark all supplements in slot as taken
    func markAsTaken(slot: ScheduleSlot, modelContext: ModelContext, user: User) {
        let todayString = IntakeLog.todayDateString()
        let log = getOrCreateLog(for: slot, date: todayString, user: user, modelContext: modelContext)

        // Mark all supplements in this slot as taken
        log.supplementIdsTaken = slot.supplementIds
        log.supplementIdsSkipped = []
        log.takenAt = Date()
        log.rescheduledTime = nil  // Clear any pending reminder

        try? modelContext.save()

        // Cancel notification since all supplements are taken
        notificationService.cancelNotificationsForSlot(slot)
    }

    /// Mark all supplements in slot as skipped
    func markAsSkipped(slot: ScheduleSlot, modelContext: ModelContext, user: User) {
        let todayString = IntakeLog.todayDateString()
        let log = getOrCreateLog(for: slot, date: todayString, user: user, modelContext: modelContext)

        // Mark all supplements in this slot as skipped
        log.supplementIdsSkipped = slot.supplementIds
        log.supplementIdsTaken = []
        log.takenAt = nil

        try? modelContext.save()
    }

    /// Undo all status for a slot
    func undoStatus(slot: ScheduleSlot, modelContext: ModelContext, user: User) {
        let todayString = IntakeLog.todayDateString()

        let existingLogs = (user.intakeLogs ?? []).filter {
            $0.scheduleSlotId == slot.id && $0.date == todayString
        }

        for log in existingLogs {
            modelContext.delete(log)
        }

        try? modelContext.save()
    }

    // MARK: - Remind Me Actions

    /// Schedule a reminder for a slot at a specific time (today only)
    func scheduleReminder(
        slot: ScheduleSlot,
        reminderTime: Date,
        modelContext: ModelContext,
        user: User
    ) {
        let todayString = IntakeLog.todayDateString()
        let log = getOrCreateLog(for: slot, date: todayString, user: user, modelContext: modelContext)

        // Store the rescheduled time
        log.rescheduledTime = reminderTime
        try? modelContext.save()

        // Calculate minutes until reminder
        let minutesUntilReminder = Int(reminderTime.timeIntervalSinceNow / 60)
        guard minutesUntilReminder > 0 else { return }

        // Get supplement names for notification
        let supplements = user.supplements ?? []
        let slotSupplements = supplements.filter { slot.supplementIds.contains($0.id) }
        let names = slotSupplements.map { $0.name }

        // Schedule notification using existing snooze infrastructure
        notificationService.scheduleSnoozeNotification(
            slotId: slot.id,
            supplementNames: names,
            supplementIds: slot.supplementIds,
            snoozeMinutes: minutesUntilReminder,
            sound: user.notificationSound
        )
    }

    /// Get rescheduled time for a slot if it exists and is in the future
    func getRescheduledTime(for slot: ScheduleSlot, logs: [IntakeLog]) -> Date? {
        let todayString = IntakeLog.todayDateString()
        guard let log = logs.first(where: { $0.scheduleSlotId == slot.id && $0.date == todayString }),
              let rescheduledTime = log.rescheduledTime,
              rescheduledTime > Date() else {
            return nil
        }
        return rescheduledTime
    }

    // MARK: - Helpers

    private func getOrCreateLog(for slot: ScheduleSlot, date: String, user: User, modelContext: ModelContext) -> IntakeLog {
        let existingLogs = (user.intakeLogs ?? []).filter {
            $0.scheduleSlotId == slot.id && $0.date == date
        }

        if let existingLog = existingLogs.first {
            return existingLog
        }

        let log = IntakeLog(
            scheduleSlotId: slot.id,
            date: date,
            supplementIdsTaken: [],
            supplementIdsSkipped: []
        )
        log.user = user
        modelContext.insert(log)
        return log
    }

    func getCompletionStats(slots: [ScheduleSlot], logs: [IntakeLog]) -> (completed: Int, total: Int) {
        let todayString = IntakeLog.todayDateString()
        let activeSlotIds = Set(slots.map { $0.id })

        // Count total supplements across all slots
        let totalSupplements = slots.reduce(0) { $0 + $1.supplementIds.count }

        // Count taken supplements only from logs matching current slots
        let todayLogs = logs.filter { $0.date == todayString && activeSlotIds.contains($0.scheduleSlotId) }
        let takenSupplements = todayLogs.reduce(0) { $0 + $1.supplementIdsTaken.count }

        return (takenSupplements, totalSupplements)
    }

    func getSupplementsForSlot(_ slot: ScheduleSlot, allSupplements: [Supplement], logs: [IntakeLog] = []) -> [Supplement] {
        let todayString = IntakeLog.todayDateString()
        var relevantIds = Set(slot.supplementIds)

        // Include supplements taken/skipped today (handles archived supplements)
        if let log = logs.first(where: { $0.scheduleSlotId == slot.id && $0.date == todayString }) {
            relevantIds.formUnion(log.supplementIdsTaken)
            relevantIds.formUnion(log.supplementIdsSkipped)
        }

        return allSupplements.filter { relevantIds.contains($0.id) }
    }

    // MARK: - Streak Methods

    func calculateStreak(slots: [ScheduleSlot], logs: [IntakeLog]) -> Int {
        return StreakService.calculateStreak(intakeLogs: logs, slots: slots)
    }

    func getSevenDayHistory(slots: [ScheduleSlot], logs: [IntakeLog]) -> [DayData] {
        return StreakService.getSevenDayHistory(intakeLogs: logs, slots: slots)
    }
}

enum SlotStatus {
    case upcoming
    case taken
    case partial   // Some supplements taken, but not all
    case skipped
    case missed

    var displayText: String {
        switch self {
        case .upcoming: return "UPCOMING"
        case .taken: return "TAKEN"
        case .partial: return "PARTIAL"
        case .skipped: return "SKIPPED"
        case .missed: return "MISSED"
        }
    }

    var color: Color {
        switch self {
        case .upcoming: return Theme.textSecondary
        case .taken: return Theme.success
        case .partial: return Theme.accent
        case .skipped: return Theme.textSecondary
        case .missed: return Theme.warning
        }
    }
}
