import Foundation

/// Represents the completion status for a single day
enum DayCompletionStatus {
    case complete      // All doses taken
    case partial       // Some doses taken
    case missed        // No doses taken (past day)
    case future        // Future day (including today if no activity yet)
    case today         // Today with some activity
}

/// Data for a single day in the 7-day visualization
struct DayData: Identifiable {
    let id = UUID()
    let date: Date
    let status: DayCompletionStatus
    let takenCount: Int
    let totalCount: Int

    var dayLetter: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE" // Single letter day (M, T, W, etc.)
        return formatter.string(from: date)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}
