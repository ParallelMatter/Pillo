import Foundation
import SwiftData

@Model
final class IntakeLog {
    var id: UUID
    var scheduleSlotId: UUID
    var date: String  // "yyyy-MM-dd" format
    var supplementIdsTaken: [UUID] = []    // Which supplements were taken
    var supplementIdsSkipped: [UUID] = []  // Which supplements were skipped
    var takenAt: Date?
    var createdAt: Date
    var rescheduledTime: Date?  // Today-only reschedule time for "Remind Me" feature

    var user: User?

    init(
        id: UUID = UUID(),
        scheduleSlotId: UUID,
        date: String,
        supplementIdsTaken: [UUID] = [],
        supplementIdsSkipped: [UUID] = [],
        takenAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.scheduleSlotId = scheduleSlotId
        self.date = date
        self.supplementIdsTaken = supplementIdsTaken
        self.supplementIdsSkipped = supplementIdsSkipped
        self.takenAt = takenAt
        self.createdAt = createdAt
    }

    /// Check if a specific supplement was taken
    func isSupplementTaken(_ supplementId: UUID) -> Bool {
        supplementIdsTaken.contains(supplementId)
    }

    /// Check if a specific supplement was skipped
    func isSupplementSkipped(_ supplementId: UUID) -> Bool {
        supplementIdsSkipped.contains(supplementId)
    }

    static func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
