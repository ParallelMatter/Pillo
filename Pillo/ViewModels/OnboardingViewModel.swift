import Foundation
import SwiftUI
import SwiftData

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case valueProposition
    case addSupplements
    case mealTimes
    case goals
    case generating
}

@Observable
class OnboardingViewModel {
    var currentStep: OnboardingStep = .welcome
    var selectedSupplements: [SupplementEntry] = []
    var breakfastTime: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    var lunchTime: Date = Calendar.current.date(from: DateComponents(hour: 12, minute: 30)) ?? Date()
    var dinnerTime: Date = Calendar.current.date(from: DateComponents(hour: 19, minute: 0)) ?? Date()
    var skipBreakfast: Bool = false
    var selectedGoals: Set<Goal> = []
    var searchQuery: String = ""
    var isGenerating: Bool = false
    var generationProgress: String = Constants.Copy.generatingStep1

    private let databaseService = SupplementDatabaseService.shared
    private let schedulingService = SchedulingService.shared
    private let notificationService = NotificationService.shared

    struct SupplementEntry: Identifiable, Equatable {
        let id = UUID()
        var reference: SupplementReference?
        var name: String
        var category: SupplementCategory
        var dosage: Double?
        var dosageUnit: String?
        var customTime: String?  // HH:mm format for manual entries

        static func == (lhs: SupplementEntry, rhs: SupplementEntry) -> Bool {
            lhs.id == rhs.id
        }
    }

    var searchResults: [SupplementSearchResult] {
        databaseService.searchSupplementsWithContext(query: searchQuery)
    }

    var canContinueFromSupplements: Bool {
        !selectedSupplements.isEmpty
    }

    func nextStep() {
        guard let nextIndex = OnboardingStep.allCases.firstIndex(where: { $0.rawValue == currentStep.rawValue + 1 }) else {
            return
        }
        withAnimation(Theme.springAnimation) {
            currentStep = OnboardingStep.allCases[nextIndex]
        }
    }

    func previousStep() {
        guard let prevIndex = OnboardingStep.allCases.firstIndex(where: { $0.rawValue == currentStep.rawValue - 1 }) else {
            return
        }
        withAnimation(Theme.springAnimation) {
            currentStep = OnboardingStep.allCases[prevIndex]
        }
    }

    func addSupplement(from reference: SupplementReference) {
        guard !selectedSupplements.contains(where: {
            $0.reference?.id == reference.id ||
            $0.name.lowercased() == reference.primaryName.lowercased()
        }) else { return }

        let entry = SupplementEntry(
            reference: reference,
            name: reference.primaryName,
            category: reference.supplementCategory,
            dosage: reference.defaultDosageMin,
            dosageUnit: reference.defaultDosageUnit
        )
        selectedSupplements.insert(entry, at: 0)
        searchQuery = ""
    }

    func addManualSupplement(name: String, category: SupplementCategory, dosage: Double?, dosageUnit: String?, customTime: String? = nil) {
        guard !selectedSupplements.contains(where: {
            $0.name.lowercased() == name.lowercased()
        }) else { return }

        let entry = SupplementEntry(
            reference: nil,
            name: name,
            category: category,
            dosage: dosage,
            dosageUnit: dosageUnit,
            customTime: customTime
        )
        selectedSupplements.insert(entry, at: 0)
    }

    func removeSupplement(_ entry: SupplementEntry) {
        selectedSupplements.removeAll { $0.id == entry.id }
    }

    func updateSupplement(_ entry: SupplementEntry, name: String, category: SupplementCategory, dosage: Double?, dosageUnit: String?, customTime: String?) {
        guard let index = selectedSupplements.firstIndex(where: { $0.id == entry.id }) else { return }

        let updatedEntry = SupplementEntry(
            reference: entry.reference,
            name: name,
            category: category,
            dosage: dosage,
            dosageUnit: dosageUnit,
            customTime: customTime
        )
        selectedSupplements[index] = updatedEntry
    }

    func toggleGoal(_ goal: Goal) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    @MainActor
    func generateSchedule(modelContext: ModelContext) async {
        isGenerating = true

        // Step 1: Analyzing
        generationProgress = Constants.Copy.generatingStep1
        try? await Task.sleep(nanoseconds: 800_000_000)

        // Create user
        let user = User(
            breakfastTime: formatTime(breakfastTime),
            lunchTime: formatTime(lunchTime),
            dinnerTime: formatTime(dinnerTime),
            skipBreakfast: skipBreakfast,
            goals: selectedGoals.map { $0.rawValue }
        )

        // Create supplements
        var supplements: [Supplement] = []
        for entry in selectedSupplements {
            let supplement = Supplement(
                name: entry.name,
                category: entry.category,
                dosage: entry.dosage,
                dosageUnit: entry.dosageUnit,
                referenceId: entry.reference?.id,
                customTime: entry.customTime
            )
            supplement.user = user
            supplements.append(supplement)
        }

        // Step 2: Optimizing
        generationProgress = Constants.Copy.generatingStep2
        try? await Task.sleep(nanoseconds: 800_000_000)

        // Generate schedule
        let slots = schedulingService.generateSchedule(
            supplements: supplements,
            breakfastTime: user.breakfastTime,
            lunchTime: user.lunchTime,
            dinnerTime: user.dinnerTime,
            skipBreakfast: user.skipBreakfast
        )

        // Step 3: Building
        generationProgress = Constants.Copy.generatingStep3
        try? await Task.sleep(nanoseconds: 800_000_000)

        // Save to database
        modelContext.insert(user)
        for supplement in supplements {
            modelContext.insert(supplement)
        }
        for slot in slots {
            slot.user = user
            modelContext.insert(slot)
        }

        try? modelContext.save()

        // Request notification permission and schedule
        let granted = await notificationService.requestAuthorization()
        if granted && user.notificationsEnabled {
            notificationService.scheduleNotifications(
                for: slots,
                supplements: supplements,
                advanceMinutes: user.notificationAdvanceMinutes,
                sound: user.notificationSound,
                repeatEnabled: user.repeatMissedNotifications,
                repeatIntervalMinutes: user.repeatIntervalMinutes,
                repeatMaxCount: user.repeatMaxCount
            )
        }

        isGenerating = false
    }
}
