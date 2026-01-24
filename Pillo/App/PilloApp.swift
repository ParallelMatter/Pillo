import SwiftUI
import SwiftData
import WidgetKit
import UserNotifications

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    var onNotificationTapped: (() -> Void)?
    var onMarkAsTaken: ((_ slotId: UUID, _ supplementIds: [UUID], _ date: String) -> Void)?
    var onSnooze: ((_ slotId: UUID, _ supplementIds: [UUID], _ supplementNames: [String], _ minutes: Int) -> Void)?

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Extract slot info from userInfo
        guard let slotIdString = userInfo["slotId"] as? String,
              let slotId = UUID(uuidString: slotIdString) else {
            // No slot info, just navigate to Today tab
            onNotificationTapped?()
            completionHandler()
            return
        }

        let supplementIdStrings = userInfo["supplementIds"] as? [String] ?? []
        let supplementIds = supplementIdStrings.compactMap { UUID(uuidString: $0) }
        let date = userInfo["date"] as? String ?? IntakeLog.todayDateString()

        switch response.actionIdentifier {
        case Constants.actionMarkAsTaken:
            onMarkAsTaken?(slotId, supplementIds, date)

        case Constants.actionSnooze15:
            // We need supplement names for the snooze notification
            // For now, pass empty array - will be filled in by the handler
            onSnooze?(slotId, supplementIds, [], 15)

        case Constants.actionSnooze30:
            onSnooze?(slotId, supplementIds, [], 30)

        case Constants.actionSnooze60:
            onSnooze?(slotId, supplementIds, [], 60)

        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification body
            onNotificationTapped?()

        default:
            onNotificationTapped?()
        }

        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
}

@main
struct PilloApp: App {
    let modelContainer: ModelContainer
    @State private var selectedTab = 0
    @State private var themeManager = ThemeManager.shared
    @State private var notificationDelegate = NotificationDelegate()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        do {
            let schema = Schema([
                User.self,
                Supplement.self,
                ScheduleSlot.self,
                IntakeLog.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(selectedTab: $selectedTab)
                .preferredColorScheme(themeManager.themeMode.colorScheme)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onAppear {
                    setupNotificationDelegate()
                    updateWidgetData()
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .active {
                        NotificationCenter.default.post(name: .appDidBecomeActive, object: nil)
                        WidgetCenter.shared.reloadAllTimelines()
                        refreshEveryNDaysNotifications()
                    }
                }
        }
        .modelContainer(modelContainer)
    }

    // MARK: - Notification Setup
    private func setupNotificationDelegate() {
        // Register notification categories with action buttons
        NotificationService.shared.registerNotificationCategories()

        notificationDelegate.onNotificationTapped = {
            selectedTab = 0  // Navigate to Today tab
        }

        notificationDelegate.onMarkAsTaken = { [self] slotId, supplementIds, date in
            Task { @MainActor in
                markSupplementsAsTaken(slotId: slotId, supplementIds: supplementIds, date: date)
            }
        }

        notificationDelegate.onSnooze = { [self] slotId, supplementIds, _, minutes in
            Task { @MainActor in
                scheduleSnoozeForSlot(slotId: slotId, supplementIds: supplementIds, minutes: minutes)
            }
        }

        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    // MARK: - Notification Action Handlers

    @MainActor
    private func markSupplementsAsTaken(slotId: UUID, supplementIds: [UUID], date: String) {
        let context = modelContainer.mainContext

        // Fetch user
        let descriptor = FetchDescriptor<User>()
        guard let user = try? context.fetch(descriptor).first else { return }

        // Check if log already exists for this slot and date
        let existingLogs = user.intakeLogs ?? []
        if let existingLog = existingLogs.first(where: { $0.scheduleSlotId == slotId && $0.date == date }) {
            // Update existing log
            existingLog.supplementIdsTaken = supplementIds
            existingLog.supplementIdsSkipped = []
            existingLog.takenAt = Date()
        } else {
            // Create new log
            let log = IntakeLog(
                scheduleSlotId: slotId,
                date: date,
                supplementIdsTaken: supplementIds,
                takenAt: Date()
            )
            log.user = user
            context.insert(log)
        }

        try? context.save()

        // Update widget
        WidgetCenter.shared.reloadAllTimelines()
    }

    @MainActor
    private func scheduleSnoozeForSlot(slotId: UUID, supplementIds: [UUID], minutes: Int) {
        let context = modelContainer.mainContext

        // Fetch user to get supplement names and sound preference
        let descriptor = FetchDescriptor<User>()
        guard let user = try? context.fetch(descriptor).first else { return }

        let supplements = user.supplements ?? []
        let matchingSupplements = supplements.filter { supplementIds.contains($0.id) }
        let names = matchingSupplements.map { $0.name }

        NotificationService.shared.scheduleSnoozeNotification(
            slotId: slotId,
            supplementNames: names,
            supplementIds: supplementIds,
            snoozeMinutes: minutes,
            sound: user.notificationSound
        )
    }

    /// Refresh notifications for slots with everyNDays frequency
    /// This is needed because everyNDays uses one-time notifications that need periodic refreshing
    @MainActor
    private func refreshEveryNDaysNotifications() {
        let context = modelContainer.mainContext

        let descriptor = FetchDescriptor<User>()
        guard let user = try? context.fetch(descriptor).first,
              user.notificationsEnabled else { return }

        let slots = user.scheduleSlots ?? []
        let hasEveryNDays = slots.contains { slot in
            if case .everyNDays = slot.frequency { return true }
            return false
        }

        // Only reschedule if there are everyNDays slots
        if hasEveryNDays {
            NotificationService.shared.scheduleNotifications(
                for: slots,
                supplements: user.supplements ?? [],
                advanceMinutes: user.notificationAdvanceMinutes,
                sound: user.notificationSound
            )
        }
    }

    // MARK: - Deep Link Handling
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "pillo" else { return }

        switch url.host {
        case "today":
            selectedTab = 0
        case "routine":
            selectedTab = 1
        case "goals":
            selectedTab = 2
        case "learn":
            selectedTab = 3
        case "settings":
            selectedTab = 4
        default:
            selectedTab = 0
        }
    }

    // MARK: - Widget Data Update
    private func updateWidgetData() {
        // This is called when app appears
        // The actual data update happens in TodayViewModel when doses are marked
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Widget Data Helper Extension
extension TodayViewModel {
    /// Update shared container data for widget
    func updateWidgetData(slots: [ScheduleSlot], logs: [IntakeLog], supplements: [Supplement]) {
        // Update progress
        let stats = getCompletionStats(slots: slots, logs: logs)
        SharedContainer.saveTodayProgress(completed: stats.completed, total: stats.total)

        // Update streak
        let streak = StreakService.calculateStreak(intakeLogs: logs, slots: slots)
        SharedContainer.saveStreak(streak)

        // Update next dose
        let nextSlot = findNextUpcomingSlot(slots: slots, logs: logs)
        if let slot = nextSlot {
            let slotSupplements = getSupplementsForSlot(slot, allSupplements: supplements)
            let supplementNames = slotSupplements.map { $0.name }
            SharedContainer.saveNextDose(
                time: slot.displayTime,
                supplements: supplementNames,
                context: slot.context.shortDisplayName
            )
        } else {
            SharedContainer.saveNextDose(time: nil, supplements: [], context: nil)
        }

        // Reload widgets
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Find the next upcoming slot that hasn't been taken
    private func findNextUpcomingSlot(slots: [ScheduleSlot], logs: [IntakeLog]) -> ScheduleSlot? {
        let sortedSlots = slots.sorted { $0.sortOrder < $1.sortOrder }

        for slot in sortedSlots {
            let status = getSlotStatus(slot: slot, logs: logs)
            if status == .upcoming {
                return slot
            }
        }

        return nil
    }
}
