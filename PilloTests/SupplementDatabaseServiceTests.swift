import XCTest
@testable import Pillo

final class SupplementDatabaseServiceTests: XCTestCase {

    var databaseService: SupplementDatabaseService!

    override func setUpWithError() throws {
        databaseService = SupplementDatabaseService.shared
    }

    // MARK: - Database Loading Tests

    func testDatabaseLoadsSuccessfully() throws {
        let supplements = databaseService.getAllSupplements()
        XCTAssertFalse(supplements.isEmpty, "Database should contain supplements")
    }

    func testDatabaseContainsCommonSupplements() throws {
        let supplements = databaseService.getAllSupplements()
        let names = supplements.flatMap { $0.names.map { $0.lowercased() } }

        XCTAssertTrue(names.contains("vitamin d") || names.contains("vitamin d3"),
                     "Database should contain Vitamin D")
        XCTAssertTrue(names.contains("iron"), "Database should contain Iron")
        XCTAssertTrue(names.contains("magnesium"), "Database should contain Magnesium")
        XCTAssertTrue(names.contains("vitamin c"), "Database should contain Vitamin C")
        XCTAssertTrue(names.contains("fish oil") || names.contains("omega-3"),
                     "Database should contain Fish Oil/Omega-3")
    }

    // MARK: - Search Tests

    func testSearchByExactName() throws {
        let results = databaseService.searchSupplements(query: "Vitamin D")

        XCTAssertFalse(results.isEmpty, "Should find Vitamin D")
        XCTAssertTrue(results.first?.names.contains("Vitamin D") ?? false)
    }

    func testSearchByPartialName() throws {
        let results = databaseService.searchSupplements(query: "mag")

        XCTAssertFalse(results.isEmpty, "Should find magnesium")
        let hasMatch = results.contains { ref in
            ref.names.contains { $0.lowercased().contains("mag") }
        }
        XCTAssertTrue(hasMatch)
    }

    func testSearchIsCaseInsensitive() throws {
        let results1 = databaseService.searchSupplements(query: "VITAMIN D")
        let results2 = databaseService.searchSupplements(query: "vitamin d")
        let results3 = databaseService.searchSupplements(query: "Vitamin D")

        XCTAssertEqual(results1.count, results2.count)
        XCTAssertEqual(results2.count, results3.count)
    }

    func testSearchWithEmptyQueryReturnsAll() throws {
        let allSupplements = databaseService.getAllSupplements()
        let emptySearchResults = databaseService.searchSupplements(query: "")

        XCTAssertEqual(allSupplements.count, emptySearchResults.count)
    }

    func testSearchWithNoMatchReturnsEmpty() throws {
        let results = databaseService.searchSupplements(query: "xyznotasupplement123")

        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - Get Supplement Tests

    func testGetSupplementById() throws {
        let supplement = databaseService.getSupplement(byId: "vitamin_d")

        XCTAssertNotNil(supplement)
        XCTAssertEqual(supplement?.id, "vitamin_d")
    }

    func testGetSupplementByName() throws {
        let supplement = databaseService.getSupplement(byName: "Vitamin D")

        XCTAssertNotNil(supplement)
        XCTAssertTrue(supplement?.names.contains("Vitamin D") ?? false)
    }

    func testGetSupplementByAlternateName() throws {
        let supplement = databaseService.getSupplement(byName: "Cholecalciferol")

        XCTAssertNotNil(supplement, "Should find by alternate name")
        XCTAssertEqual(supplement?.id, "vitamin_d")
    }

    func testGetNonexistentSupplementReturnsNil() throws {
        let byId = databaseService.getSupplement(byId: "nonexistent_id")
        let byName = databaseService.getSupplement(byName: "Nonexistent Supplement")

        XCTAssertNil(byId)
        XCTAssertNil(byName)
    }

    // MARK: - Interaction Tests

    func testGetInteractionsForSupplement() throws {
        let interactions = databaseService.getInteractions(for: "calcium")

        XCTAssertFalse(interactions.isEmpty, "Calcium should have interactions")

        let hasIronInteraction = interactions.contains {
            $0.supplementA == "iron" || $0.supplementB == "iron"
        }
        XCTAssertTrue(hasIronInteraction, "Calcium should interact with iron")
    }

    func testGetInteractionsBetweenSupplements() throws {
        let interactions = databaseService.getInteractionsBetween(supplements: ["calcium", "iron"])

        XCTAssertFalse(interactions.isEmpty, "Calcium and iron should have interaction")
        XCTAssertEqual(interactions.count, 1)
    }

    func testNoInteractionsBetweenCompatibleSupplements() throws {
        let interactions = databaseService.getInteractionsBetween(supplements: ["vitamin_d", "vitamin_k"])

        XCTAssertTrue(interactions.isEmpty, "Vitamin D and K should not have negative interactions")
    }

    // MARK: - Synergy Tests

    func testGetSynergiesForSupplement() throws {
        let synergies = databaseService.getSynergies(for: "iron")

        let hasVitaminCSynergy = synergies.contains {
            $0.supplementA == "vitamin_c" || $0.supplementB == "vitamin_c"
        }
        XCTAssertTrue(hasVitaminCSynergy, "Iron should have synergy with Vitamin C")
    }

    func testGetSynergiesBetweenSupplements() throws {
        let synergies = databaseService.getSynergiesBetween(supplements: ["vitamin_d", "vitamin_k"])

        XCTAssertFalse(synergies.isEmpty, "Vitamin D and K should have synergy")
    }

    // MARK: - Goal Tests

    func testGetSupplementsForGoal() throws {
        let energySupplements = databaseService.getSupplementsForGoal(.energy)

        XCTAssertFalse(energySupplements.isEmpty, "Should have supplements for energy goal")

        let bComplexIncluded = energySupplements.contains { ref in
            ref.goalRelevance.contains("energy")
        }
        XCTAssertTrue(bComplexIncluded)
    }

    func testGetSupplementsForSleepGoal() throws {
        let sleepSupplements = databaseService.getSupplementsForGoal(.sleep)

        XCTAssertFalse(sleepSupplements.isEmpty, "Should have supplements for sleep goal")

        let hasMagnesium = sleepSupplements.contains { $0.id == "magnesium" }
        XCTAssertTrue(hasMagnesium, "Magnesium should be in sleep supplements")
    }

    // MARK: - Supplement Reference Tests

    func testSupplementReferenceProperties() throws {
        guard let vitaminD = databaseService.getSupplement(byId: "vitamin_d") else {
            XCTFail("Should find Vitamin D")
            return
        }

        XCTAssertEqual(vitaminD.primaryName, "Vitamin D")
        XCTAssertEqual(vitaminD.supplementCategory, .vitaminFatSoluble)
        XCTAssertTrue(vitaminD.requiresFat)
        XCTAssertFalse(vitaminD.absorptionNotes.isEmpty)
    }

    func testSupplementDisplayDosageRange() throws {
        guard let vitaminD = databaseService.getSupplement(byId: "vitamin_d") else {
            XCTFail("Should find Vitamin D")
            return
        }

        let dosageRange = vitaminD.displayDosageRange
        XCTAssertFalse(dosageRange.isEmpty)
        XCTAssertTrue(dosageRange.contains("IU"))
    }
}
