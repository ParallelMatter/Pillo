import XCTest
import SwiftData
@testable import Pillo

final class PilloTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

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
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }

    // MARK: - User Tests

    func testUserCreation() throws {
        let user = User()
        modelContext.insert(user)

        XCTAssertNotNil(user.id)
        XCTAssertEqual(user.breakfastTime, "08:00")
        XCTAssertEqual(user.lunchTime, "12:30")
        XCTAssertEqual(user.dinnerTime, "19:00")
        XCTAssertFalse(user.skipBreakfast)
        XCTAssertTrue(user.notificationsEnabled)
    }

    func testUserWithCustomMealTimes() throws {
        let user = User(
            breakfastTime: "07:30",
            lunchTime: "13:00",
            dinnerTime: "18:30"
        )
        modelContext.insert(user)

        XCTAssertEqual(user.breakfastTime, "07:30")
        XCTAssertEqual(user.lunchTime, "13:00")
        XCTAssertEqual(user.dinnerTime, "18:30")
    }

    // MARK: - Supplement Tests

    func testSupplementCreation() throws {
        let supplement = Supplement(
            name: "Vitamin D",
            category: .vitaminFatSoluble,
            dosage: 5000,
            dosageUnit: "IU"
        )
        modelContext.insert(supplement)

        XCTAssertEqual(supplement.name, "Vitamin D")
        XCTAssertEqual(supplement.category, .vitaminFatSoluble)
        XCTAssertEqual(supplement.dosage, 5000)
        XCTAssertEqual(supplement.dosageUnit, "IU")
        XCTAssertTrue(supplement.isActive)
    }

    func testSupplementDisplayDosage() throws {
        let supplement1 = Supplement(
            name: "Iron",
            category: .mineral,
            dosage: 65,
            dosageUnit: "mg"
        )

        XCTAssertEqual(supplement1.displayDosage, "65mg")

        let supplement2 = Supplement(
            name: "Biotin",
            category: .vitaminWaterSoluble,
            dosage: 2.5,
            dosageUnit: "mg"
        )

        XCTAssertEqual(supplement2.displayDosage, "2.5mg")

        let supplement3 = Supplement(
            name: "Test",
            category: .other
        )

        XCTAssertEqual(supplement3.displayDosage, "")
    }

    func testSupplementUserRelationship() throws {
        let user = User()
        let supplement = Supplement(name: "Magnesium", category: .mineral)
        supplement.user = user

        modelContext.insert(user)
        modelContext.insert(supplement)

        XCTAssertEqual(supplement.user?.id, user.id)
    }

    // MARK: - Schedule Slot Tests

    func testScheduleSlotCreation() throws {
        let slot = ScheduleSlot(
            time: "07:00",
            context: .emptyStomach,
            supplementIds: [UUID(), UUID()],
            explanation: "Iron absorbs best on empty stomach."
        )
        modelContext.insert(slot)

        XCTAssertEqual(slot.time, "07:00")
        XCTAssertEqual(slot.context, .emptyStomach)
        XCTAssertEqual(slot.supplementIds.count, 2)
        XCTAssertFalse(slot.explanation.isEmpty)
    }

    func testScheduleSlotDisplayTime() throws {
        let slot = ScheduleSlot(time: "14:30", context: .betweenMeals)

        XCTAssertEqual(slot.displayTime, "2:30 PM")
    }

    func testMealContextDisplayNames() throws {
        XCTAssertEqual(MealContext.emptyStomach.displayName, "Empty stomach")
        XCTAssertEqual(MealContext.withBreakfast.displayName, "With breakfast")
        XCTAssertEqual(MealContext.withLunch.displayName, "With lunch")
        XCTAssertEqual(MealContext.withDinner.displayName, "With dinner")
        XCTAssertEqual(MealContext.betweenMeals.displayName, "Between meals")
        XCTAssertEqual(MealContext.bedtime.displayName, "Before bed")
    }

    // MARK: - Intake Log Tests

    func testIntakeLogCreation() throws {
        let slotId = UUID()
        let log = IntakeLog(
            scheduleSlotId: slotId,
            date: "2025-01-22",
            status: .taken,
            takenAt: Date()
        )
        modelContext.insert(log)

        XCTAssertEqual(log.scheduleSlotId, slotId)
        XCTAssertEqual(log.status, .taken)
        XCTAssertNotNil(log.takenAt)
    }

    func testIntakeLogTodayDateString() throws {
        let dateString = IntakeLog.todayDateString()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let expected = formatter.string(from: Date())

        XCTAssertEqual(dateString, expected)
    }

    // MARK: - Goal Tests

    func testGoalDisplayNames() throws {
        XCTAssertEqual(Goal.energy.displayName, "Better energy")
        XCTAssertEqual(Goal.sleep.displayName, "Improved sleep")
        XCTAssertEqual(Goal.immunity.displayName, "Immune support")
        XCTAssertEqual(Goal.boneHealth.displayName, "Bone health")
        XCTAssertEqual(Goal.heartHealth.displayName, "Heart health")
        XCTAssertEqual(Goal.skinHairNails.displayName, "Skin/hair/nails")
        XCTAssertEqual(Goal.athleticPerformance.displayName, "Athletic performance")
        XCTAssertEqual(Goal.stress.displayName, "Stress management")
        XCTAssertEqual(Goal.cognitive.displayName, "Cognitive function")
    }

    func testGoalIcons() throws {
        XCTAssertEqual(Goal.energy.icon, "bolt.fill")
        XCTAssertEqual(Goal.sleep.icon, "moon.fill")
        XCTAssertEqual(Goal.immunity.icon, "shield.fill")
    }

    // MARK: - Supplement Category Tests

    func testSupplementCategoryDisplayNames() throws {
        XCTAssertEqual(SupplementCategory.vitaminFatSoluble.displayName, "Fat-Soluble Vitamin")
        XCTAssertEqual(SupplementCategory.vitaminWaterSoluble.displayName, "Water-Soluble Vitamin")
        XCTAssertEqual(SupplementCategory.mineral.displayName, "Mineral")
        XCTAssertEqual(SupplementCategory.omega.displayName, "Omega/Fish Oil")
        XCTAssertEqual(SupplementCategory.probiotic.displayName, "Probiotic")
        XCTAssertEqual(SupplementCategory.herbal.displayName, "Herbal/Adaptogen")
        XCTAssertEqual(SupplementCategory.aminoAcid.displayName, "Amino Acid")
        XCTAssertEqual(SupplementCategory.other.displayName, "Other")
    }
}
