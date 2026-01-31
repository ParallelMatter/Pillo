import Foundation
import SwiftData

@Model
final class User {
    var id: UUID
    var createdAt: Date
    var breakfastTime: String
    var lunchTime: String
    var dinnerTime: String
    var skipBreakfast: Bool
    var goals: [String]
    var notificationsEnabled: Bool
    var notificationAdvanceMinutes: Int
    var notificationSound: String
    var repeatMissedNotifications: Bool
    var repeatIntervalMinutes: Int
    var repeatMaxCount: Int

    @Relationship(deleteRule: .cascade, inverse: \Supplement.user)
    var supplements: [Supplement]?

    @Relationship(deleteRule: .cascade, inverse: \ScheduleSlot.user)
    var scheduleSlots: [ScheduleSlot]?

    @Relationship(deleteRule: .cascade, inverse: \IntakeLog.user)
    var intakeLogs: [IntakeLog]?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        breakfastTime: String = Constants.defaultBreakfastTime,
        lunchTime: String = Constants.defaultLunchTime,
        dinnerTime: String = Constants.defaultDinnerTime,
        skipBreakfast: Bool = false,
        goals: [String] = [],
        notificationsEnabled: Bool = true,
        notificationAdvanceMinutes: Int = Constants.defaultAdvanceMinutes,
        notificationSound: String = "subtle",
        repeatMissedNotifications: Bool = false,
        repeatIntervalMinutes: Int = 30,
        repeatMaxCount: Int = 2
    ) {
        self.id = id
        self.createdAt = createdAt
        self.breakfastTime = breakfastTime
        self.lunchTime = lunchTime
        self.dinnerTime = dinnerTime
        self.skipBreakfast = skipBreakfast
        self.goals = goals
        self.notificationsEnabled = notificationsEnabled
        self.notificationAdvanceMinutes = notificationAdvanceMinutes
        self.notificationSound = notificationSound
        self.repeatMissedNotifications = repeatMissedNotifications
        self.repeatIntervalMinutes = repeatIntervalMinutes
        self.repeatMaxCount = repeatMaxCount
    }
}
