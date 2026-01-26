import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    private init() {}

    // MARK: - Register Notification Categories

    func registerNotificationCategories() {
        let markAsTakenAction = UNNotificationAction(
            identifier: Constants.actionMarkAsTaken,
            title: "Mark as Taken",
            options: [.authenticationRequired]
        )

        let snooze15Action = UNNotificationAction(
            identifier: Constants.actionSnooze15,
            title: "15 min",
            options: []
        )

        let snooze30Action = UNNotificationAction(
            identifier: Constants.actionSnooze30,
            title: "30 min",
            options: []
        )

        let snooze60Action = UNNotificationAction(
            identifier: Constants.actionSnooze60,
            title: "1 hour",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: Constants.notificationCategoryIdentifier,
            actions: [markAsTakenAction, snooze15Action, snooze30Action, snooze60Action],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Schedule Notifications

    func scheduleNotifications(
        for slots: [ScheduleSlot],
        supplements: [Supplement],
        advanceMinutes: Int = 5,
        sound: String = "subtle"
    ) {
        // Clear existing notifications
        cancelAllNotifications()

        for slot in slots {
            scheduleNotification(
                for: slot,
                supplements: supplements,
                advanceMinutes: advanceMinutes,
                sound: sound
            )
        }
    }

    private func scheduleNotification(
        for slot: ScheduleSlot,
        supplements: [Supplement],
        advanceMinutes: Int,
        sound: String
    ) {
        let slotSupplements = supplements.filter { slot.supplementIds.contains($0.id) }
        guard !slotSupplements.isEmpty else { return }

        let content = createNotificationContent(
            for: slot,
            supplements: slotSupplements,
            sound: sound
        )

        // Parse the slot time and get time components
        guard let triggerDate = calculateNotificationDate(
            slotTime: slot.time,
            advanceMinutes: advanceMinutes
        ) else { return }

        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: triggerDate)

        // Schedule based on frequency
        switch slot.frequency {
        case .daily:
            scheduleDailyNotification(slot: slot, content: content, timeComponents: timeComponents)

        case .specificDays(let days):
            scheduleSpecificDaysNotifications(slot: slot, content: content, timeComponents: timeComponents, days: days)

        case .weekly(let day):
            scheduleWeeklyNotification(slot: slot, content: content, timeComponents: timeComponents, day: day)

        case .everyNDays(let interval, let startDate):
            scheduleEveryNDaysNotifications(
                slot: slot,
                content: content,
                interval: interval,
                startDate: startDate,
                slotTime: slot.time,
                advanceMinutes: advanceMinutes
            )
        }
    }

    private func createNotificationContent(
        for slot: ScheduleSlot,
        supplements: [Supplement],
        sound: String
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Time for your supplements"

        let names = supplements.map { $0.name }
        if names.count == 1 {
            content.body = "Take your \(names[0]) (\(slot.context.displayName.lowercased()))"
        } else if names.count == 2 {
            content.body = "Take your \(names[0]) and \(names[1])"
        } else {
            content.body = "Take your \(names[0]) and \(names.count - 1) others"
        }

        content.categoryIdentifier = Constants.notificationCategoryIdentifier

        // Add userInfo for handling notification actions
        content.userInfo = [
            "slotId": slot.id.uuidString,
            "supplementIds": supplements.map { $0.id.uuidString },
            "date": IntakeLog.todayDateString()
        ]

        switch sound {
        case "subtle", "standard":
            content.sound = UNNotificationSound.default
        default:
            content.sound = nil
        }

        return content
    }

    // MARK: - Frequency-Specific Scheduling

    private func scheduleDailyNotification(
        slot: ScheduleSlot,
        content: UNMutableNotificationContent,
        timeComponents: DateComponents
    ) {
        let trigger = UNCalendarNotificationTrigger(dateMatching: timeComponents, repeats: true)
        addNotificationRequest(identifier: slot.id.uuidString, content: content, trigger: trigger)
    }

    private func scheduleSpecificDaysNotifications(
        slot: ScheduleSlot,
        content: UNMutableNotificationContent,
        timeComponents: DateComponents,
        days: Set<ScheduleFrequency.Weekday>
    ) {
        for day in days {
            var components = timeComponents
            components.weekday = day.rawValue

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let identifier = "\(slot.id.uuidString)-\(day.shortName)"
            addNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        }
    }

    private func scheduleWeeklyNotification(
        slot: ScheduleSlot,
        content: UNMutableNotificationContent,
        timeComponents: DateComponents,
        day: ScheduleFrequency.Weekday
    ) {
        var components = timeComponents
        components.weekday = day.rawValue

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let identifier = "\(slot.id.uuidString)-weekly"
        addNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }

    private func scheduleEveryNDaysNotifications(
        slot: ScheduleSlot,
        content: UNMutableNotificationContent,
        interval: Int,
        startDate: Date,
        slotTime: String,
        advanceMinutes: Int
    ) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Find next occurrence from today
        var nextDate = calendar.startOfDay(for: startDate)
        while nextDate < today {
            guard let newDate = calendar.date(byAdding: .day, value: interval, to: nextDate) else { break }
            nextDate = newDate
        }

        // Schedule next 8 occurrences (iOS limits pending notifications to 64 total)
        for i in 0..<8 {
            guard let occurrenceDate = calendar.date(byAdding: .day, value: i * interval, to: nextDate) else { continue }

            // Calculate the full trigger date with time
            guard let triggerDate = calculateNotificationDateForDate(
                date: occurrenceDate,
                slotTime: slotTime,
                advanceMinutes: advanceMinutes
            ) else { continue }

            // Skip if in the past
            if triggerDate < Date() { continue }

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let identifier = "\(slot.id.uuidString)-every\(interval)-\(i)"
            addNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        }
    }

    private func addNotificationRequest(
        identifier: String,
        content: UNMutableNotificationContent,
        trigger: UNCalendarNotificationTrigger
    ) {
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    private func calculateNotificationDate(slotTime: String, advanceMinutes: Int) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let time = formatter.date(from: slotTime) else { return nil }

        // Get today's date with the slot time
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        guard let slotDate = calendar.date(from: components) else { return nil }

        // Subtract advance minutes
        return calendar.date(byAdding: .minute, value: -advanceMinutes, to: slotDate)
    }

    private func calculateNotificationDateForDate(date: Date, slotTime: String, advanceMinutes: Int) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let time = formatter.date(from: slotTime) else { return nil }

        // Get the specified date with the slot time
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        guard let slotDate = calendar.date(from: components) else { return nil }

        // Subtract advance minutes
        return calendar.date(byAdding: .minute, value: -advanceMinutes, to: slotDate)
    }

    // MARK: - Cancel Notifications

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func cancelNotification(for slotId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [slotId.uuidString]
        )
    }

    /// Cancel all pending notifications for a slot (handles all frequency types)
    func cancelNotificationsForSlot(_ slot: ScheduleSlot) {
        var identifiersToCancel: [String] = []
        let slotIdString = slot.id.uuidString

        switch slot.frequency {
        case .daily:
            identifiersToCancel.append(slotIdString)

        case .specificDays(let days):
            for day in days {
                identifiersToCancel.append("\(slotIdString)-\(day.shortName)")
            }

        case .weekly(_):
            identifiersToCancel.append("\(slotIdString)-weekly")

        case .everyNDays(let interval, _):
            // Cancel all 8 scheduled occurrences
            for i in 0..<8 {
                identifiersToCancel.append("\(slotIdString)-every\(interval)-\(i)")
            }
        }

        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: identifiersToCancel
        )

        // Also cancel any pending snooze notifications for this slot
        cancelSnoozeNotifications(for: slot.id)
    }

    /// Cancel any pending snooze notifications for a slot
    func cancelSnoozeNotifications(for slotId: UUID) {
        let prefix = "snooze-\(slotId.uuidString)-"

        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let snoozeIds = requests
                .map { $0.identifier }
                .filter { $0.hasPrefix(prefix) }

            if !snoozeIds.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(
                    withIdentifiers: snoozeIds
                )
            }
        }
    }

    // MARK: - Snooze Notifications

    func scheduleSnoozeNotification(
        slotId: UUID,
        supplementNames: [String],
        supplementIds: [UUID],
        snoozeMinutes: Int,
        sound: String
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Reminder"

        if supplementNames.count == 1 {
            content.body = "Time to take your \(supplementNames[0])"
        } else if supplementNames.count == 2 {
            content.body = "Time to take your \(supplementNames[0]) and \(supplementNames[1])"
        } else {
            content.body = "Time to take your \(supplementNames[0]) and \(supplementNames.count - 1) others"
        }

        content.categoryIdentifier = Constants.notificationCategoryIdentifier

        content.userInfo = [
            "slotId": slotId.uuidString,
            "supplementIds": supplementIds.map { $0.uuidString },
            "date": IntakeLog.todayDateString(),
            "isSnoozed": true
        ]

        switch sound {
        case "subtle", "standard":
            content.sound = UNNotificationSound.default
        default:
            content.sound = nil
        }

        // One-time trigger after snooze duration
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(snoozeMinutes * 60),
            repeats: false
        )

        // Unique identifier for snooze notifications
        let identifier = "snooze-\(slotId.uuidString)-\(Int(Date().timeIntervalSince1970))"

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling snooze notification: \(error)")
            }
        }
    }

    // MARK: - Badge Management

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("Error clearing badge: \(error)")
            }
        }
    }
}
