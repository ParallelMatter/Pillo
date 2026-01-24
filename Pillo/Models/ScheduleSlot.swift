import Foundation
import SwiftData

// MARK: - Schedule Frequency

enum ScheduleFrequency: Codable, Equatable {
    case daily
    case specificDays(Set<Weekday>)
    case everyNDays(interval: Int, startDate: Date)
    case weekly(Weekday)

    enum Weekday: Int, Codable, CaseIterable, Identifiable, Hashable {
        case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

        var id: Int { rawValue }

        var shortName: String {
            switch self {
            case .sunday: return "Sun"
            case .monday: return "Mon"
            case .tuesday: return "Tue"
            case .wednesday: return "Wed"
            case .thursday: return "Thu"
            case .friday: return "Fri"
            case .saturday: return "Sat"
            }
        }

        var initial: String {
            switch self {
            case .sunday: return "S"
            case .monday: return "M"
            case .tuesday: return "T"
            case .wednesday: return "W"
            case .thursday: return "T"
            case .friday: return "F"
            case .saturday: return "S"
            }
        }

        var fullName: String {
            switch self {
            case .sunday: return "Sunday"
            case .monday: return "Monday"
            case .tuesday: return "Tuesday"
            case .wednesday: return "Wednesday"
            case .thursday: return "Thursday"
            case .friday: return "Friday"
            case .saturday: return "Saturday"
            }
        }
    }

    var displayName: String {
        switch self {
        case .daily:
            return "Every day"
        case .specificDays(let days):
            if days.count == 5 && !days.contains(.saturday) && !days.contains(.sunday) {
                return "Weekdays"
            } else if days.count == 2 && days.contains(.saturday) && days.contains(.sunday) {
                return "Weekends"
            } else {
                let sortedDays = days.sorted { $0.rawValue < $1.rawValue }
                return sortedDays.map { $0.shortName }.joined(separator: ", ")
            }
        case .everyNDays(let interval, _):
            return "Every \(interval) days"
        case .weekly(let day):
            return "Weekly on \(day.fullName)"
        }
    }
}

// MARK: - Meal Context

enum MealContext: String, Codable {
    case emptyStomach = "empty_stomach"
    case withBreakfast = "with_breakfast"
    case withLunch = "with_lunch"
    case withDinner = "with_dinner"
    case betweenMeals = "between_meals"
    case bedtime = "bedtime"

    var displayName: String {
        switch self {
        case .emptyStomach: return "Empty stomach"
        case .withBreakfast: return "With breakfast"
        case .withLunch: return "With lunch"
        case .withDinner: return "With dinner"
        case .betweenMeals: return "Between meals"
        case .bedtime: return "Before bed"
        }
    }

    var shortDisplayName: String {
        switch self {
        case .emptyStomach: return "Empty stomach"
        case .withBreakfast: return "With food"
        case .withLunch: return "With food"
        case .withDinner: return "With food"
        case .betweenMeals: return "Between meals"
        case .bedtime: return "Before bed"
        }
    }
}

@Model
final class ScheduleSlot {
    var id: UUID
    var time: String  // "HH:mm" format
    var context: MealContext
    var supplementIds: [UUID]
    var explanation: String
    var createdAt: Date
    var sortOrder: Int

    // Schedule frequency - stored as encoded Data for SwiftData compatibility
    var frequencyData: Data?

    var user: User?

    init(
        id: UUID = UUID(),
        time: String,
        context: MealContext,
        supplementIds: [UUID] = [],
        explanation: String = "",
        createdAt: Date = Date(),
        sortOrder: Int = 0,
        frequency: ScheduleFrequency = .daily
    ) {
        self.id = id
        self.time = time
        self.context = context
        self.supplementIds = supplementIds
        self.explanation = explanation
        self.createdAt = createdAt
        self.sortOrder = sortOrder
        self.frequencyData = try? JSONEncoder().encode(frequency)
    }

    // MARK: - Frequency Computed Property

    var frequency: ScheduleFrequency {
        get {
            guard let data = frequencyData else { return .daily }
            return (try? JSONDecoder().decode(ScheduleFrequency.self, from: data)) ?? .daily
        }
        set {
            frequencyData = try? JSONEncoder().encode(newValue)
        }
    }

    // MARK: - Active Date Check

    /// Check if this slot should be active on a given date
    func isActiveOn(date: Date) -> Bool {
        let calendar = Calendar.current
        let weekdayComponent = calendar.component(.weekday, from: date)

        switch frequency {
        case .daily:
            return true

        case .specificDays(let days):
            guard let weekday = ScheduleFrequency.Weekday(rawValue: weekdayComponent) else { return false }
            return days.contains(weekday)

        case .everyNDays(let interval, let startDate):
            let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: date).day ?? 0
            return daysSinceStart >= 0 && daysSinceStart % interval == 0

        case .weekly(let day):
            return weekdayComponent == day.rawValue
        }
    }

    var timeAsDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let time = formatter.date(from: self.time) else { return nil }

        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        return calendar.date(from: components)
    }

    var displayTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let date = formatter.date(from: time) else { return time }

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "h:mm a"
        return outputFormatter.string(from: date)
    }
}
