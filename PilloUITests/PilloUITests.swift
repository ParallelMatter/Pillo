import XCTest

final class PilloUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Onboarding Tests

    func testOnboardingWelcomeScreen() throws {
        app.launch()

        // Verify welcome screen elements
        XCTAssertTrue(app.staticTexts["PILLO"].exists)
        XCTAssertTrue(app.staticTexts["The difference between taking supplements"].exists)
        XCTAssertTrue(app.buttons["Get Started"].exists)
    }

    func testOnboardingNavigation() throws {
        app.launch()

        // Tap Get Started
        app.buttons["Get Started"].tap()

        // Should be on Add Vitamins screen
        XCTAssertTrue(app.staticTexts["WHAT DO YOU TAKE?"].waitForExistence(timeout: 2))

        // Search for a supplement
        let searchField = app.textFields["Search supplements"]
        XCTAssertTrue(searchField.exists)
    }

    func testAddSupplementDuringOnboarding() throws {
        app.launch()

        // Navigate to Add Vitamins
        app.buttons["Get Started"].tap()

        // Wait for search field
        let searchField = app.textFields["Search supplements"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))

        // Search for Vitamin D
        searchField.tap()
        searchField.typeText("Vitamin D")

        // Tap on first result
        let vitaminDCell = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Vitamin D'")).firstMatch
        if vitaminDCell.waitForExistence(timeout: 2) {
            vitaminDCell.tap()
        }

        // Continue button should appear
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2))
    }

    func testMealTimesScreen() throws {
        app.launch()

        // Navigate through onboarding
        app.buttons["Get Started"].tap()

        // Add a supplement manually to enable Continue
        app.buttons["Add Manually"].tap()

        let nameField = app.textFields["Supplement name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Test Supplement")

        app.buttons["Add Supplement"].tap()

        // Now Continue should be available
        app.buttons["Continue"].tap()

        // Should be on Meal Times screen
        XCTAssertTrue(app.staticTexts["WHEN DO YOU EAT?"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["BREAKFAST"].exists)
        XCTAssertTrue(app.staticTexts["LUNCH"].exists)
        XCTAssertTrue(app.staticTexts["DINNER"].exists)
    }

    // MARK: - Main App Tests

    func testTabBarNavigation() throws {
        // This test assumes user has completed onboarding
        // You would need to set up test data or use launch arguments to skip onboarding

        app.launchArguments.append("--skip-onboarding")
        app.launch()

        // Check tab bar exists
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 3) {
            // Verify tabs
            XCTAssertTrue(tabBar.buttons["Today"].exists)
            XCTAssertTrue(tabBar.buttons["Routine"].exists)
            XCTAssertTrue(tabBar.buttons["Goals"].exists)
            XCTAssertTrue(tabBar.buttons["Learn"].exists)
            XCTAssertTrue(tabBar.buttons["Settings"].exists)
        }
    }

    func testVitaminsTabSearch() throws {
        app.launchArguments.append("--skip-onboarding")
        app.launch()

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 3) else { return }

        // Navigate to Vitamins tab
        tabBar.buttons["Routine"].tap()

        // Verify search bar exists
        let searchField = app.textFields["Search supplements"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
    }

    func testLearnTabArticles() throws {
        app.launchArguments.append("--skip-onboarding")
        app.launch()

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 3) else { return }

        // Navigate to Learn tab
        tabBar.buttons["Learn"].tap()

        // Verify Learn header
        XCTAssertTrue(app.staticTexts["LEARN"].waitForExistence(timeout: 2))
    }

    func testSettingsTab() throws {
        app.launchArguments.append("--skip-onboarding")
        app.launch()

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 3) else { return }

        // Navigate to Settings tab
        tabBar.buttons["Settings"].tap()

        // Verify Settings header
        XCTAssertTrue(app.staticTexts["SETTINGS"].waitForExistence(timeout: 2))
    }

    // MARK: - Accessibility Tests

    func testAccessibilityLabels() throws {
        app.launch()

        // Check that Get Started button has accessibility
        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(getStartedButton.exists)
        XCTAssertTrue(getStartedButton.isHittable)
    }

    // MARK: - Performance Tests

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
