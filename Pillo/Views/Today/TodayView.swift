import SwiftUI
import SwiftData
import UIKit

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @Query private var supplements: [Supplement]
    @Query private var intakeLogs: [IntakeLog]
    @State private var viewModel = TodayViewModel()
    @State private var refreshID = UUID()
    @State private var showingCalendar = false
    @State private var selectedSlotForReminder: ScheduleSlot?
    @State private var selectedSlotForTimePicker: ScheduleSlot?
    @State private var customReminderTime = Date()
    @State private var pendingRemindMeSlotId: UUID?
    @State private var pendingTimePickerSlotId: UUID?

    private var user: User? { users.first }
    private var slots: [ScheduleSlot] {
        let today = Date()
        let todayString = IntakeLog.todayDateString()

        return (user?.scheduleSlots ?? [])
            .filter { slot in
                // Show if slot has active supplements scheduled today
                if !slot.supplementIds.isEmpty && slot.isActiveOn(date: today) {
                    // Check if slot time has passed
                    if let slotTime = slot.timeAsDate, slotTime < Date() {
                        // Time has passed - check if there's an IntakeLog
                        let hasLog = intakeLogs.contains {
                            $0.scheduleSlotId == slot.id && $0.date == todayString
                        }

                        if !hasLog {
                            // No log - check if user had opportunity to take any supplement
                            let slotSupplements = supplements.filter { slot.supplementIds.contains($0.id) }
                            let anyExistedBeforeSlotTime = slotSupplements.contains { supplement in
                                // Supplement existed before today's slot time
                                supplement.createdAt < slotTime
                            }

                            if !anyExistedBeforeSlotTime {
                                // All supplements were added after the time - don't show (start tomorrow)
                                return false
                            }
                        }
                    }
                    return true
                }
                // Also show if slot has taken items today (archived supplements)
                if let log = intakeLogs.first(where: { $0.scheduleSlotId == slot.id && $0.date == todayString }) {
                    return !log.supplementIdsTaken.isEmpty
                }
                return false
            }
            .sorted { slot1, slot2 in
                // Get effective sort time for each slot (rescheduled time or original slot time)
                let time1 = getEffectiveSortTime(for: slot1)
                let time2 = getEffectiveSortTime(for: slot2)
                return time1 < time2
            }
    }

    /// Get the effective time for sorting - uses rescheduled time if present, otherwise slot's original time
    private func getEffectiveSortTime(for slot: ScheduleSlot) -> Date {
        let todayString = IntakeLog.todayDateString()

        // Check for rescheduled time in today's log
        if let log = intakeLogs.first(where: { $0.scheduleSlotId == slot.id && $0.date == todayString }),
           let rescheduledTime = log.rescheduledTime {
            return rescheduledTime
        }

        // Fall back to slot's original time (convert "HH:mm" to today's date)
        let components = slot.time.split(separator: ":").compactMap { Int($0) }
        if components.count == 2 {
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            dateComponents.hour = components[0]
            dateComponents.minute = components[1]
            if let date = Calendar.current.date(from: dateComponents) {
                return date
            }
        }

        // Ultimate fallback - use sort order as seconds from midnight
        return Calendar.current.startOfDay(for: Date()).addingTimeInterval(TimeInterval(slot.sortOrder * 60))
    }

    /// Set of archived supplement IDs
    private var archivedSupplementIds: Set<UUID> {
        Set(supplements.filter { $0.isArchived }.map { $0.id })
    }

    /// Get set of supplement IDs that are marked as taken for a slot today
    private func getSupplementsTaken(for slot: ScheduleSlot) -> Set<UUID> {
        let todayString = IntakeLog.todayDateString()
        guard let log = intakeLogs.first(where: { $0.scheduleSlotId == slot.id && $0.date == todayString }) else {
            return []
        }
        return Set(log.supplementIdsTaken)
    }

    /// Get set of supplement IDs that are marked as skipped for a slot today
    private func getSupplementsSkipped(for slot: ScheduleSlot) -> Set<UUID> {
        let todayString = IntakeLog.todayDateString()
        guard let log = intakeLogs.first(where: { $0.scheduleSlotId == slot.id && $0.date == todayString }) else {
            return []
        }
        return Set(log.supplementIdsSkipped)
    }

    /// Get rescheduled time for a slot if it exists
    private func getRescheduledTime(for slot: ScheduleSlot) -> Date? {
        return viewModel.getRescheduledTime(for: slot, logs: Array(intakeLogs))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if let user = user {
                    ScrollView {
                        VStack(spacing: Theme.spacingLG) {
                            // Header
                            TodayHeader()

                            // Streak Card
                            StreakCard(
                                streak: viewModel.calculateStreak(slots: Array(user.scheduleSlots ?? []), logs: intakeLogs, supplements: Array(supplements)),
                                sevenDayHistory: viewModel.getSevenDayHistory(slots: Array(user.scheduleSlots ?? []), logs: intakeLogs, supplements: Array(supplements)),
                                onTap: {
                                    showingCalendar = true
                                }
                            )
                            .padding(.horizontal, Theme.spacingLG)
                            .sheet(isPresented: $showingCalendar) {
                                CalendarSheet(
                                    intakeLogs: Array(intakeLogs),
                                    slots: Array(user.scheduleSlots ?? []),
                                    supplements: Array(supplements),
                                    trackingStartDate: user.createdAt
                                )
                            }

                            // Progress Card
                            ProgressCard(
                                stats: viewModel.getCompletionStats(slots: slots, logs: intakeLogs, supplements: Array(supplements))
                            )
                            .padding(.horizontal, Theme.spacingLG)

                            // Timeline
                            VStack(spacing: Theme.spacingMD) {
                                ForEach(slots) { slot in
                                    let slotSupplements = viewModel.getSupplementsForSlot(slot, allSupplements: supplements, logs: intakeLogs)
                                    let supplementsTaken = getSupplementsTaken(for: slot)
                                    let supplementsSkipped = getSupplementsSkipped(for: slot)

                                    TimeSlotCard(
                                        slot: slot,
                                        supplements: slotSupplements,
                                        status: viewModel.getSlotStatus(slot: slot, supplements: slotSupplements, logs: intakeLogs),
                                        supplementsTaken: supplementsTaken,
                                        supplementsSkipped: supplementsSkipped,
                                        archivedSupplementIds: archivedSupplementIds,
                                        rescheduledTime: getRescheduledTime(for: slot),
                                        onSupplementToggle: { supplementId in
                                            withAnimation {
                                                // Toggle: if taken, undo; if not taken, mark as taken
                                                if supplementsTaken.contains(supplementId) {
                                                    viewModel.undoSupplementStatus(supplementId: supplementId, slot: slot, modelContext: modelContext, user: user)
                                                } else {
                                                    viewModel.markSupplementAsTaken(supplementId: supplementId, slot: slot, modelContext: modelContext, user: user)
                                                }
                                                viewModel.updateWidgetData(slots: slots, logs: user.intakeLogs ?? [], supplements: supplements)
                                            }
                                        },
                                        onMarkAllTaken: {
                                            withAnimation {
                                                viewModel.markAsTaken(slot: slot, modelContext: modelContext, user: user)
                                                viewModel.updateWidgetData(slots: slots, logs: user.intakeLogs ?? [], supplements: supplements)
                                            }
                                        },
                                        onRemindMe: {
                                            selectedSlotForReminder = slot
                                        },
                                        onUndo: {
                                            withAnimation {
                                                viewModel.undoStatus(slot: slot, modelContext: modelContext, user: user)
                                                viewModel.updateWidgetData(slots: slots, logs: user.intakeLogs ?? [], supplements: supplements)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, Theme.spacingLG)
                            .padding(.bottom, Theme.spacingXXL)
                        }
                    }
                    .id(refreshID)
                } else {
                    Text("No schedule found")
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .onAppear {
                if let _ = user {
                    viewModel.updateWidgetData(slots: slots, logs: intakeLogs, supplements: supplements)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .appDidBecomeActive)) { _ in
                refreshID = UUID()
                if let _ = user {
                    viewModel.updateWidgetData(slots: slots, logs: intakeLogs, supplements: supplements)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                refreshID = UUID()
                if let _ = user {
                    viewModel.updateWidgetData(slots: slots, logs: intakeLogs, supplements: supplements)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .openRemindMeSheet)) { notification in
                guard let userInfo = notification.userInfo,
                      let slotIdString = userInfo["slotId"] as? String,
                      let slotId = UUID(uuidString: slotIdString) else { return }

                if let slot = slots.first(where: { $0.id == slotId }) {
                    selectedSlotForReminder = slot
                } else {
                    // Store pending ID to retry when slots load (e.g., cold start from notification)
                    pendingRemindMeSlotId = slotId
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .openTimePickerSheet)) { notification in
                guard let userInfo = notification.userInfo,
                      let slotIdString = userInfo["slotId"] as? String,
                      let slotId = UUID(uuidString: slotIdString) else { return }

                if let slot = slots.first(where: { $0.id == slotId }) {
                    selectedSlotForTimePicker = slot
                } else {
                    // Store pending ID to retry when slots load (e.g., cold start from notification)
                    pendingTimePickerSlotId = slotId
                }
            }
            .sheet(item: $selectedSlotForReminder) { slot in
                if let user = user {
                    RemindMeSheet(
                        slot: slot,
                        supplements: viewModel.getSupplementsForSlot(slot, allSupplements: supplements, logs: intakeLogs),
                        onSelectTime: { reminderTime in
                            viewModel.scheduleReminder(
                                slot: slot,
                                reminderTime: reminderTime,
                                modelContext: modelContext,
                                user: user
                            )
                            viewModel.updateWidgetData(slots: slots, logs: user.intakeLogs ?? [], supplements: supplements)
                        }
                    )
                }
            }
            .sheet(item: $selectedSlotForTimePicker) { slot in
                if let user = user {
                    TimePickerSheet(
                        selectedTime: $customReminderTime,
                        onConfirm: {
                            viewModel.scheduleReminder(
                                slot: slot,
                                reminderTime: customReminderTime,
                                modelContext: modelContext,
                                user: user
                            )
                            viewModel.updateWidgetData(slots: slots, logs: user.intakeLogs ?? [], supplements: supplements)
                        }
                    )
                }
            }
            .onChange(of: slots) { _, newSlots in
                // Handle pending slot ID from notification when app cold-starts
                if let pendingId = pendingRemindMeSlotId,
                   let slot = newSlots.first(where: { $0.id == pendingId }) {
                    selectedSlotForReminder = slot
                    pendingRemindMeSlotId = nil
                }
                if let pendingId = pendingTimePickerSlotId,
                   let slot = newSlots.first(where: { $0.id == pendingId }) {
                    selectedSlotForTimePicker = slot
                    pendingTimePickerSlotId = nil
                }
            }
        }
    }
}

struct TodayHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingXS) {
            Text("TODAY")
                .font(Theme.headerFont)
                .tracking(2)
                .foregroundColor(Theme.textSecondary)

            Text(Date(), format: .dateTime.month(.wide).day())
                .font(Theme.displayFont)
                .foregroundColor(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.spacingLG)
        .padding(.top, Theme.spacingMD)
    }
}

struct ProgressCard: View {
    let stats: (completed: Int, total: Int)

    private var progress: Double {
        guard stats.total > 0 else { return 0 }
        return Double(stats.completed) / Double(stats.total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMD) {
            Text("\(stats.completed) of \(stats.total) completed")
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textPrimary)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Theme.border)
                        .frame(height: 4)
                        .cornerRadius(2)

                    Rectangle()
                        .fill(Theme.success)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 4)

            Text("\(Int(progress * 100))%")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
        }
        .cardStyle()
    }
}

#Preview {
    TodayView()
        .preferredColorScheme(.light)
        .modelContainer(for: [User.self, Supplement.self, ScheduleSlot.self, IntakeLog.self], inMemory: true)
}

// MARK: - Custom Notification Name
extension Notification.Name {
    static let appDidBecomeActive = Notification.Name("appDidBecomeActive")
}
