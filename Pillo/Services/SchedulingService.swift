import Foundation
import SwiftData

class SchedulingService {
    static let shared = SchedulingService()

    private let databaseService = SupplementDatabaseService.shared

    private init() {}

    // MARK: - Time Slot Definition

    struct TimeSlot {
        let time: String
        let context: MealContext
        var supplements: [(Supplement, SupplementReference?)]
        var explanation: String
        var frequency: ScheduleFrequency = .daily

        var sortOrder: Int {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            guard let date = formatter.date(from: time) else { return 0 }
            return Int(date.timeIntervalSince1970)
        }
    }

    // MARK: - Schedule Generation

    func generateSchedule(
        supplements: [Supplement],
        breakfastTime: String,
        lunchTime: String,
        dinnerTime: String,
        skipBreakfast: Bool
    ) -> [ScheduleSlot] {
        // Separate supplements with custom times from algorithm-assigned ones
        let customTimeSupplements = supplements.filter { $0.customTime != nil }
        let algorithmSupplements = supplements.filter { $0.customTime == nil }

        // Create available time slots for algorithm-assigned supplements
        let slots = createTimeSlots(
            breakfastTime: breakfastTime,
            lunchTime: lunchTime,
            dinnerTime: dinnerTime,
            skipBreakfast: skipBreakfast
        )

        // Get references for algorithm supplements
        let supplementsWithRefs = algorithmSupplements.map { supp -> (Supplement, SupplementReference?) in
            let ref = databaseService.getSupplement(byId: supp.referenceId ?? "")
                ?? databaseService.getSupplement(byName: supp.name)
            return (supp, ref)
        }

        // Assign algorithm supplements to ideal slots
        var assignments = assignSupplementsToSlots(supplementsWithRefs, slots: slots)

        // Resolve conflicts
        assignments = resolveConflicts(assignments)

        // Create custom time slots for manually-timed supplements
        // Group by both time AND frequency (different frequencies need separate slots)
        var customSlots: [TimeSlot] = []
        for supplement in customTimeSupplements {
            if let customTime = supplement.customTime {
                let frequency = supplement.customFrequency ?? .daily
                // Check if a slot already exists at this time with the same frequency
                if let existingIndex = customSlots.firstIndex(where: {
                    $0.time == customTime && $0.frequency == frequency
                }) {
                    customSlots[existingIndex].supplements.append((supplement, nil))
                } else {
                    customSlots.append(TimeSlot(
                        time: customTime,
                        context: .betweenMeals,  // Custom times use generic context
                        supplements: [(supplement, nil)],
                        explanation: "Scheduled at your preferred time.",
                        frequency: frequency
                    ))
                }
            }
        }

        // Combine algorithm slots and custom slots
        let allSlots = assignments + customSlots

        // Convert to ScheduleSlots
        return createScheduleSlots(from: allSlots)
    }

    // MARK: - Time Slot Creation

    private func createTimeSlots(
        breakfastTime: String,
        lunchTime: String,
        dinnerTime: String,
        skipBreakfast: Bool
    ) -> [TimeSlot] {
        var slots: [TimeSlot] = []

        let breakfast = parseTime(breakfastTime)
        let lunch = parseTime(lunchTime)
        let dinner = parseTime(dinnerTime)

        // Empty stomach (60 min before breakfast)
        if !skipBreakfast {
            let emptyStomachTime = addMinutes(-60, to: breakfast)
            slots.append(TimeSlot(
                time: formatTime(emptyStomachTime),
                context: .emptyStomach,
                supplements: [],
                explanation: ""
            ))

            // With breakfast
            slots.append(TimeSlot(
                time: breakfastTime,
                context: .withBreakfast,
                supplements: [],
                explanation: ""
            ))
        }

        // Between breakfast and lunch
        if !skipBreakfast {
            let midMorning = midpoint(between: breakfast, and: lunch)
            slots.append(TimeSlot(
                time: formatTime(midMorning),
                context: .betweenMeals,
                supplements: [],
                explanation: ""
            ))
        }

        // With lunch
        slots.append(TimeSlot(
            time: lunchTime,
            context: .withLunch,
            supplements: [],
            explanation: ""
        ))

        // Between lunch and dinner
        let midAfternoon = midpoint(between: lunch, and: dinner)
        slots.append(TimeSlot(
            time: formatTime(midAfternoon),
            context: .betweenMeals,
            supplements: [],
            explanation: ""
        ))

        // With dinner
        slots.append(TimeSlot(
            time: dinnerTime,
            context: .withDinner,
            supplements: [],
            explanation: ""
        ))

        // Bedtime (2 hours after dinner)
        let bedtime = addMinutes(120, to: dinner)
        slots.append(TimeSlot(
            time: formatTime(bedtime),
            context: .bedtime,
            supplements: [],
            explanation: ""
        ))

        return slots
    }

    // MARK: - Supplement Assignment

    private func assignSupplementsToSlots(
        _ supplements: [(Supplement, SupplementReference?)],
        slots: [TimeSlot]
    ) -> [TimeSlot] {
        var mutableSlots = slots

        for (supplement, reference) in supplements {
            let idealContext = determineIdealContext(for: supplement, reference: reference)
            if let slotIndex = mutableSlots.firstIndex(where: { $0.context == idealContext }) {
                mutableSlots[slotIndex].supplements.append((supplement, reference))
            } else if let firstMealSlot = mutableSlots.firstIndex(where: {
                [.withBreakfast, .withLunch, .withDinner].contains($0.context)
            }) {
                mutableSlots[firstMealSlot].supplements.append((supplement, reference))
            }
        }

        return mutableSlots
    }

    private func determineIdealContext(
        for supplement: Supplement,
        reference: SupplementReference?
    ) -> MealContext {
        // Check reference timing
        if let ref = reference {
            switch ref.timing {
            case "empty_stomach":
                return .emptyStomach
            case "with_food":
                return .withBreakfast  // Default to breakfast for fat-soluble
            case "evening", "bedtime":
                return .bedtime
            case "flexible":
                // Water-soluble can go anywhere, prefer morning for energy
                if ref.goalRelevance.contains("energy") {
                    return .withBreakfast
                }
                return .betweenMeals
            default:
                break
            }
        }

        // Fallback based on category
        switch supplement.category {
        case .vitaminFatSoluble, .omega:
            return .withBreakfast
        case .vitaminWaterSoluble:
            return .withBreakfast
        case .mineral:
            // Iron is special - empty stomach
            if supplement.name.lowercased().contains("iron") {
                return .emptyStomach
            }
            // Calcium, Magnesium - space them out
            if supplement.name.lowercased().contains("magnesium") {
                return .bedtime
            }
            return .betweenMeals
        case .probiotic:
            return .emptyStomach
        case .herbal:
            // Adaptogens like Ashwagandha often better in evening
            if supplement.name.lowercased().contains("ashwagandha") ||
               supplement.name.lowercased().contains("melatonin") {
                return .bedtime
            }
            return .withBreakfast
        case .aminoAcid:
            return .emptyStomach
        case .other:
            return .withBreakfast
        }
    }

    // MARK: - Conflict Resolution

    private func resolveConflicts(_ slots: [TimeSlot]) -> [TimeSlot] {
        var mutableSlots = slots

        // Get all active interactions
        let allSupplementIds = slots.flatMap { slot in
            slot.supplements.compactMap { $0.1?.id }
        }
        let interactions = databaseService.getInteractionsBetween(supplements: allSupplementIds)

        // Check each slot for conflicts
        for (slotIndex, slot) in mutableSlots.enumerated() {
            let supplementRefs = slot.supplements.compactMap { $0.1 }
            let ids = supplementRefs.map { $0.id }

            // Check for conflicting supplements in same slot
            for interaction in interactions {
                if ids.contains(interaction.supplementA) && ids.contains(interaction.supplementB) {
                    // Move the second one to a different slot
                    if let suppIndex = slot.supplements.firstIndex(where: { $0.1?.id == interaction.supplementB }),
                       let newSlotIndex = findAlternativeSlot(for: mutableSlots[slotIndex].supplements[suppIndex], currentIndex: slotIndex, slots: &mutableSlots) {
                        let supp = mutableSlots[slotIndex].supplements.remove(at: suppIndex)
                        mutableSlots[newSlotIndex].supplements.append(supp)
                    }
                }
            }
        }

        return mutableSlots
    }

    private func findAlternativeSlot(
        for supplement: (Supplement, SupplementReference?),
        currentIndex: Int,
        slots: inout [TimeSlot]
    ) -> Int? {
        // Find a slot at least 2 hours away
        let currentTime = parseTime(slots[currentIndex].time)

        for (index, slot) in slots.enumerated() where index != currentIndex {
            let slotTime = parseTime(slot.time)
            let hoursDiff = abs(currentTime.timeIntervalSince(slotTime) / 3600)

            if hoursDiff >= 2 {
                // Check if moving here would create new conflicts
                let existingIds = slot.supplements.compactMap { $0.1?.id }
                if let suppId = supplement.1?.id {
                    let newInteractions = databaseService.getInteractionsBetween(supplements: existingIds + [suppId])
                    if newInteractions.isEmpty {
                        return index
                    }
                } else {
                    return index
                }
            }
        }

        // Fallback: find any different slot
        for (index, _) in slots.enumerated() where index != currentIndex {
            return index
        }

        return nil
    }

    // MARK: - Schedule Slot Creation

    private func createScheduleSlots(from timeSlots: [TimeSlot]) -> [ScheduleSlot] {
        // Filter non-empty slots and sort by time
        let sortedSlots = timeSlots
            .filter { !$0.supplements.isEmpty }
            .sorted { $0.sortOrder < $1.sortOrder }

        return sortedSlots
            .enumerated()
            .map { (index, slot) in
                let explanation = generateExplanation(for: slot)
                return ScheduleSlot(
                    time: slot.time,
                    context: slot.context,
                    supplementIds: slot.supplements.map { $0.0.id },
                    explanation: explanation,
                    sortOrder: index,
                    frequency: slot.frequency
                )
            }
    }

    private func generateExplanation(for slot: TimeSlot) -> String {
        var explanations: [String] = []

        switch slot.context {
        case .emptyStomach:
            let hasIron = slot.supplements.contains { $0.0.name.lowercased().contains("iron") }
            let hasVitaminC = slot.supplements.contains {
                $0.0.name.lowercased().contains("vitamin c") || $0.0.name.lowercased() == "c"
            }

            if hasIron && hasVitaminC {
                explanations.append("Iron absorbs best on an empty stomach. Vitamin C significantly boosts iron absorption.")
            } else if hasIron {
                explanations.append("Iron absorbs best before food—food can cut absorption by 50%.")
            }

            if slot.supplements.contains(where: { $0.0.category == .probiotic }) {
                explanations.append("Probiotics may survive better on an empty stomach.")
            }

            if slot.supplements.contains(where: { $0.0.category == .aminoAcid }) {
                explanations.append("Amino acids absorb better without competing proteins from food.")
            }

        case .withBreakfast, .withLunch, .withDinner:
            let hasFatSoluble = slot.supplements.contains {
                $0.0.category == .vitaminFatSoluble || $0.0.category == .omega
            }
            if hasFatSoluble {
                explanations.append("Fat-soluble vitamins require dietary fat to absorb properly. Your meal provides the fat they need.")
            }

            if slot.context == .withDinner {
                let hasZinc = slot.supplements.contains { $0.0.name.lowercased().contains("zinc") }
                if hasZinc {
                    explanations.append("Zinc absorption is enhanced by protein, making dinner an ideal time.")
                }
            }

        case .betweenMeals:
            let hasCalcium = slot.supplements.contains { $0.0.name.lowercased().contains("calcium") }
            if hasCalcium {
                explanations.append("Calcium competes with iron and other minerals for absorption. We've spaced them apart.")
            }

        case .bedtime:
            let hasMagnesium = slot.supplements.contains { $0.0.name.lowercased().contains("magnesium") }
            let hasAshwagandha = slot.supplements.contains { $0.0.name.lowercased().contains("ashwagandha") }

            if hasMagnesium {
                explanations.append("Magnesium promotes muscle relaxation and may support better sleep.")
            }
            if hasAshwagandha {
                explanations.append("Ashwagandha can help manage stress and support restful sleep.")
            }
        }

        return explanations.joined(separator: " ")
    }

    // MARK: - Time Utilities

    private func parseTime(_ timeString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString) ?? Date()
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func addMinutes(_ minutes: Int, to date: Date) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: date) ?? date
    }

    private func midpoint(between date1: Date, and date2: Date) -> Date {
        let interval = date2.timeIntervalSince(date1) / 2
        return date1.addingTimeInterval(interval)
    }
}
