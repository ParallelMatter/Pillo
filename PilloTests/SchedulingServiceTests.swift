import XCTest
import SwiftData
@testable import Pillo

final class SchedulingServiceTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var schedulingService: SchedulingService!

    override func setUpWithError() throws {
        let schema = Schema([
            User.self,
            Supplement.self,
            ScheduleSlot.self,
            IntakeLog.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = modelContainer.mainContext
        schedulingService = SchedulingService.shared
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }

    // MARK: - Schedule Generation Tests

    func testGenerateScheduleCreatesSlots() throws {
        let supplements = [
            Supplement(name: "Vitamin D", category: .vitaminFatSoluble, dosage: 5000, dosageUnit: "IU"),
            Supplement(name: "Iron", category: .mineral, dosage: 65, dosageUnit: "mg"),
            Supplement(name: "Magnesium", category: .mineral, dosage: 400, dosageUnit: "mg")
        ]

        let slots = schedulingService.generateSchedule(
            supplements: supplements,
            breakfastTime: "08:00",
            lunchTime: "12:30",
            dinnerTime: "19:00",
            skipBreakfast: false
        )

        XCTAssertFalse(slots.isEmpty, "Schedule should have at least one slot")
        XCTAssertTrue(slots.count <= 7, "Should not create more than 7 slots")
    }

    func testIronScheduledOnEmptyStomach() throws {
        let supplements = [
            Supplement(name: "Iron", category: .mineral, dosage: 65, dosageUnit: "mg")
        ]

        let slots = schedulingService.generateSchedule(
            supplements: supplements,
            breakfastTime: "08:00",
            lunchTime: "12:30",
            dinnerTime: "19:00",
            skipBreakfast: false
        )

        let ironSlot = slots.first { slot in
            supplements.first { slot.supplementIds.contains($0.id) && $0.name == "Iron" } != nil
        }

        XCTAssertNotNil(ironSlot, "Iron should be scheduled")
        XCTAssertEqual(ironSlot?.context, .emptyStomach, "Iron should be on empty stomach")
    }

    func testFatSolubleVitaminsScheduledWithFood() throws {
        let supplements = [
            Supplement(name: "Vitamin D", category: .vitaminFatSoluble, dosage: 5000, dosageUnit: "IU"),
            Supplement(name: "Fish Oil", category: .omega, dosage: 1000, dosageUnit: "mg")
        ]

        let slots = schedulingService.generateSchedule(
            supplements: supplements,
            breakfastTime: "08:00",
            lunchTime: "12:30",
            dinnerTime: "19:00",
            skipBreakfast: false
        )

        for slot in slots {
            for supplementId in slot.supplementIds {
                if let supplement = supplements.first(where: { $0.id == supplementId }) {
                    if supplement.category == .vitaminFatSoluble || supplement.category == .omega {
                        let mealContexts: [MealContext] = [.withBreakfast, .withLunch, .withDinner]
                        XCTAssertTrue(mealContexts.contains(slot.context),
                                    "\(supplement.name) should be with a meal")
                    }
                }
            }
        }
    }

    func testMagnesiumScheduledInEvening() throws {
        let supplements = [
            Supplement(name: "Magnesium", category: .mineral, dosage: 400, dosageUnit: "mg")
        ]

        let slots = schedulingService.generateSchedule(
            supplements: supplements,
            breakfastTime: "08:00",
            lunchTime: "12:30",
            dinnerTime: "19:00",
            skipBreakfast: false
        )

        let magSlot = slots.first { slot in
            supplements.first { slot.supplementIds.contains($0.id) && $0.name == "Magnesium" } != nil
        }

        XCTAssertNotNil(magSlot, "Magnesium should be scheduled")
        XCTAssertEqual(magSlot?.context, .bedtime, "Magnesium should be at bedtime")
    }

    func testScheduleWithSkippedBreakfast() throws {
        let supplements = [
            Supplement(name: "Vitamin D", category: .vitaminFatSoluble)
        ]

        let slots = schedulingService.generateSchedule(
            supplements: supplements,
            breakfastTime: "08:00",
            lunchTime: "12:30",
            dinnerTime: "19:00",
            skipBreakfast: true
        )

        let hasBreakfastSlot = slots.contains { $0.context == .withBreakfast }
        XCTAssertFalse(hasBreakfastSlot, "Should not have breakfast slot when skipped")

        let hasEmptyStomachMorning = slots.contains { $0.context == .emptyStomach }
        XCTAssertFalse(hasEmptyStomachMorning, "Should not have morning empty stomach when breakfast skipped")
    }

    func testScheduleGeneratesExplanations() throws {
        let supplements = [
            Supplement(name: "Iron", category: .mineral, dosage: 65, dosageUnit: "mg"),
            Supplement(name: "Vitamin C", category: .vitaminWaterSoluble, dosage: 500, dosageUnit: "mg")
        ]

        let slots = schedulingService.generateSchedule(
            supplements: supplements,
            breakfastTime: "08:00",
            lunchTime: "12:30",
            dinnerTime: "19:00",
            skipBreakfast: false
        )

        let slotsWithSupplements = slots.filter { !$0.supplementIds.isEmpty }

        for slot in slotsWithSupplements {
            XCTAssertFalse(slot.explanation.isEmpty, "Slots with supplements should have explanations")
        }
    }

    func testScheduleSlotsAreSorted() throws {
        let supplements = [
            Supplement(name: "Vitamin D", category: .vitaminFatSoluble),
            Supplement(name: "Iron", category: .mineral),
            Supplement(name: "Magnesium", category: .mineral),
            Supplement(name: "Calcium", category: .mineral)
        ]

        let slots = schedulingService.generateSchedule(
            supplements: supplements,
            breakfastTime: "08:00",
            lunchTime: "12:30",
            dinnerTime: "19:00",
            skipBreakfast: false
        )

        for i in 0..<(slots.count - 1) {
            XCTAssertLessThanOrEqual(slots[i].sortOrder, slots[i + 1].sortOrder,
                                     "Slots should be sorted by sortOrder")
        }
    }

    // MARK: - Empty Input Tests

    func testEmptySupplementsReturnsEmptySchedule() throws {
        let slots = schedulingService.generateSchedule(
            supplements: [],
            breakfastTime: "08:00",
            lunchTime: "12:30",
            dinnerTime: "19:00",
            skipBreakfast: false
        )

        XCTAssertTrue(slots.isEmpty, "Empty supplements should produce empty schedule")
    }
}
