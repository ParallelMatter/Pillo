import Foundation

struct Constants {
    // MARK: - Default Times
    static let defaultBreakfastTime = "08:00"
    static let defaultLunchTime = "12:30"
    static let defaultDinnerTime = "19:00"

    // MARK: - Notification Settings
    static let defaultAdvanceMinutes = 5
    static let notificationCategoryIdentifier = "PILLO_SUPPLEMENT_REMINDER"

    // Notification Action Identifiers
    static let actionMarkAsTaken = "MARK_AS_TAKEN"
    static let actionSnooze15 = "SNOOZE_15"
    static let actionSnooze30 = "SNOOZE_30"
    static let actionSnooze60 = "SNOOZE_60"
    static let actionPickTime = "PICK_TIME"

    // MARK: - Interaction Spacing (in hours)
    static let mineralCompetitionSpacing = 2.0
    static let caffeineSpacing = 1.0
    static let fiberSpacing = 2.0

    // MARK: - Time Slots
    static let emptyStomachOffsetMinutes = -60  // Before breakfast
    static let betweenMealsOffsetMinutes = 0    // Calculated as midpoint
    static let bedtimeOffsetMinutes = 120       // After dinner

    // MARK: - Copy
    struct Copy {
        static let welcomeTitle = "PILLO"
        static let welcomeSubtitle = "The difference between taking supplements\nand absorbing them."
        static let getStarted = "Get Started"

        // Value Proposition Pages
        static let valueProp1Headline = "SMART\nTIMING"
        static let valueProp1Subtitle = "Timed to your day,\nfor full absorption."
        static let valueProp2Headline = "AVOID\nCONFLICTS"
        static let valueProp2Subtitle = "Some supplements block each other.\nWe space them out."
        static let valueProp3Headline = "BETTER\nTOGETHER"
        static let valueProp3Subtitle = "Some supplements boost each other.\nWe pair them up."

        static let addSupplementsTitle = "WHAT DO YOU TAKE?"
        static let addSupplementsSubtitle = "We'll make it all work. At the right time."

        static let mealTimesTitle = "WHEN DO YOU EAT?"
        static let mealTimesSubtitle = "Roughly. We're not counting calories."

        static let goalsTitle = "ANY SPECIFIC GOALS?"
        static let goalsSubtitle = "Optional. Helps us prioritize."

        static let generatingStep1 = "Analyzing interactions..."
        static let generatingStep2 = "Optimizing absorption..."
        static let generatingStep3 = "Building your schedule..."
    }
}
