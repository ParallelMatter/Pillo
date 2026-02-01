import Foundation

/// Shared container for data exchange between main app and widgets
struct SharedContainer {
    static let appGroupIdentifier = "group.com.suplo.shared"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    // MARK: - Keys
    private enum Keys {
        static let todayProgress = "todayProgress"
        static let todayTotal = "todayTotal"
        static let currentStreak = "currentStreak"
        static let nextDoseTime = "nextDoseTime"
        static let nextDoseSupplements = "nextDoseSupplements"
        static let nextDoseContext = "nextDoseContext"
        static let lastUpdated = "lastUpdated"
        static let hasSeenRoutineHint = "hasSeenRoutineHint"
    }

    // MARK: - Today Progress
    static func saveTodayProgress(completed: Int, total: Int) {
        sharedDefaults?.set(completed, forKey: Keys.todayProgress)
        sharedDefaults?.set(total, forKey: Keys.todayTotal)
        sharedDefaults?.set(Date(), forKey: Keys.lastUpdated)
    }

    static func getTodayProgress() -> (completed: Int, total: Int) {
        let completed = sharedDefaults?.integer(forKey: Keys.todayProgress) ?? 0
        let total = sharedDefaults?.integer(forKey: Keys.todayTotal) ?? 0
        return (completed, total)
    }

    // MARK: - Streak
    static func saveStreak(_ streak: Int) {
        sharedDefaults?.set(streak, forKey: Keys.currentStreak)
    }

    static func getStreak() -> Int {
        sharedDefaults?.integer(forKey: Keys.currentStreak) ?? 0
    }

    // MARK: - Next Dose
    static func saveNextDose(time: String?, supplements: [String], context: String?) {
        sharedDefaults?.set(time, forKey: Keys.nextDoseTime)
        sharedDefaults?.set(supplements, forKey: Keys.nextDoseSupplements)
        sharedDefaults?.set(context, forKey: Keys.nextDoseContext)
    }

    static func getNextDose() -> (time: String?, supplements: [String], context: String?) {
        let time = sharedDefaults?.string(forKey: Keys.nextDoseTime)
        let supplements = sharedDefaults?.stringArray(forKey: Keys.nextDoseSupplements) ?? []
        let context = sharedDefaults?.string(forKey: Keys.nextDoseContext)
        return (time, supplements, context)
    }

    // MARK: - Last Updated
    static func getLastUpdated() -> Date? {
        sharedDefaults?.object(forKey: Keys.lastUpdated) as? Date
    }

    // MARK: - Routine Hint
    static func hasSeenRoutineHint() -> Bool {
        sharedDefaults?.bool(forKey: Keys.hasSeenRoutineHint) ?? false
    }

    static func setRoutineHintSeen() {
        sharedDefaults?.set(true, forKey: Keys.hasSeenRoutineHint)
    }

    // MARK: - Clear All
    static func clearAll() {
        let keys = [
            Keys.todayProgress,
            Keys.todayTotal,
            Keys.currentStreak,
            Keys.nextDoseTime,
            Keys.nextDoseSupplements,
            Keys.nextDoseContext,
            Keys.lastUpdated
        ]
        keys.forEach { sharedDefaults?.removeObject(forKey: $0) }
    }
}

/// Data model for widget timeline entries
struct WidgetData: Codable {
    let completed: Int
    let total: Int
    let streak: Int
    let nextDoseTime: String?
    let nextDoseSupplements: [String]
    let nextDoseContext: String?
    let lastUpdated: Date

    var progressPercentage: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var isComplete: Bool {
        total > 0 && completed >= total
    }

    static var placeholder: WidgetData {
        WidgetData(
            completed: 2,
            total: 5,
            streak: 7,
            nextDoseTime: "8:00 AM",
            nextDoseSupplements: ["Vitamin D", "Fish Oil"],
            nextDoseContext: "With breakfast",
            lastUpdated: Date()
        )
    }

    static func fromSharedContainer() -> WidgetData {
        let progress = SharedContainer.getTodayProgress()
        let nextDose = SharedContainer.getNextDose()

        return WidgetData(
            completed: progress.completed,
            total: progress.total,
            streak: SharedContainer.getStreak(),
            nextDoseTime: nextDose.time,
            nextDoseSupplements: nextDose.supplements,
            nextDoseContext: nextDose.context,
            lastUpdated: SharedContainer.getLastUpdated() ?? Date()
        )
    }
}
