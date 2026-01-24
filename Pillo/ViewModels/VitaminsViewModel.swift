import Foundation
import SwiftUI
import SwiftData

@Observable
class VitaminsViewModel {
    var searchQuery: String = ""
    var showingAddSheet: Bool = false
    var selectedSupplement: Supplement?

    private let databaseService = SupplementDatabaseService.shared
    private let schedulingService = SchedulingService.shared

    var searchResults: [SupplementReference] {
        databaseService.searchSupplements(query: searchQuery)
    }

    func getInteractionsForUserSupplements(_ supplements: [Supplement]) -> [SupplementInteraction] {
        // Filter out archived supplements
        let activeSupplements = supplements.filter { !$0.isArchived }
        let ids = activeSupplements.compactMap { supp -> String? in
            if let refId = supp.referenceId {
                return refId
            }
            return databaseService.getSupplement(byName: supp.name)?.id
        }
        return databaseService.getInteractionsBetween(supplements: ids)
    }

    func getSynergiesForUserSupplements(_ supplements: [Supplement]) -> [SupplementSynergy] {
        // Filter out archived supplements
        let activeSupplements = supplements.filter { !$0.isArchived }
        let ids = activeSupplements.compactMap { supp -> String? in
            if let refId = supp.referenceId {
                return refId
            }
            return databaseService.getSupplement(byName: supp.name)?.id
        }
        return databaseService.getSynergiesBetween(supplements: ids)
    }

    func getReferenceInfo(for supplement: Supplement) -> SupplementReference? {
        if let refId = supplement.referenceId {
            return databaseService.getSupplement(byId: refId)
        }
        return databaseService.getSupplement(byName: supplement.name)
    }

    func groupSupplementsBySlot(supplements: [Supplement], slots: [ScheduleSlot]) -> [(String, [Supplement])] {
        // Filter out archived supplements
        let activeSupplements = supplements.filter { !$0.isArchived }

        var groups: [(String, [Supplement])] = []

        for slot in slots.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            let slotSupplements = activeSupplements.filter { slot.supplementIds.contains($0.id) }
            if !slotSupplements.isEmpty {
                let groupName = "\(slot.displayTime) - \(slot.context.shortDisplayName)"
                groups.append((groupName, slotSupplements))
            }
        }

        return groups
    }

    /// Groups supplements by slot, returning slot info for editing
    func groupSupplementsBySlotWithSlot(supplements: [Supplement], slots: [ScheduleSlot]) -> [(slot: ScheduleSlot, supplements: [Supplement])] {
        // Filter out archived supplements
        let activeSupplements = supplements.filter { !$0.isArchived }

        var groups: [(slot: ScheduleSlot, supplements: [Supplement])] = []

        for slot in slots.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            let slotSupplements = activeSupplements.filter { slot.supplementIds.contains($0.id) }
            if !slotSupplements.isEmpty {
                groups.append((slot: slot, supplements: slotSupplements))
            }
        }

        return groups
    }

    func userHasSupplement(referenceId: String, user: User) -> Bool {
        // Only check non-archived supplements
        (user.supplements ?? []).contains { $0.referenceId == referenceId && !$0.isArchived }
    }

    func userHasSupplement(name: String, user: User) -> Bool {
        // Only check non-archived supplements
        (user.supplements ?? []).contains { $0.name.lowercased() == name.lowercased() && !$0.isArchived }
    }

    /// Returns true if added successfully, false if duplicate exists
    func addSupplement(
        from reference: SupplementReference,
        dosage: Double?,
        dosageUnit: String?,
        form: SupplementForm?,
        to user: User,
        modelContext: ModelContext
    ) -> Bool {
        // Check for duplicate
        if userHasSupplement(referenceId: reference.id, user: user) {
            return false
        }

        let supplement = Supplement(
            name: reference.primaryName,
            category: reference.supplementCategory,
            dosage: dosage,
            dosageUnit: dosageUnit,
            form: form,
            referenceId: reference.id
        )
        supplement.user = user
        modelContext.insert(supplement)

        // Regenerate schedule
        regenerateSchedule(for: user, modelContext: modelContext)
        return true
    }

    /// Returns true if added successfully, false if duplicate exists
    func addManualSupplement(
        name: String,
        category: SupplementCategory,
        dosage: Double?,
        dosageUnit: String?,
        form: SupplementForm?,
        to user: User,
        modelContext: ModelContext
    ) -> Bool {
        // Check for duplicate by name
        if userHasSupplement(name: name, user: user) {
            return false
        }

        let supplement = Supplement(
            name: name,
            category: category,
            dosage: dosage,
            dosageUnit: dosageUnit,
            form: form
        )
        supplement.user = user
        modelContext.insert(supplement)

        regenerateSchedule(for: user, modelContext: modelContext)
        return true
    }

    func deleteSupplement(_ supplement: Supplement, user: User, modelContext: ModelContext) {
        // Check if this supplement has been taken historically
        if checkForHistoricalLogs(supplementId: supplement.id, user: user) {
            // Archive instead of delete - preserve for historical records
            supplement.isArchived = true
            supplement.archivedAt = Date()
        } else {
            // No historical data - safe to delete completely
            modelContext.delete(supplement)
        }

        regenerateSchedule(for: user, modelContext: modelContext)
    }

    /// Check if a supplement has any historical intake logs (was marked as taken)
    private func checkForHistoricalLogs(supplementId: UUID, user: User) -> Bool {
        let logs = user.intakeLogs ?? []
        return logs.contains { $0.supplementIdsTaken.contains(supplementId) }
    }

    func updateSupplement(
        _ supplement: Supplement,
        dosage: Double?,
        dosageUnit: String?,
        form: SupplementForm?,
        modelContext: ModelContext
    ) {
        supplement.dosage = dosage
        supplement.dosageUnit = dosageUnit
        supplement.form = form
        try? modelContext.save()
    }

    private func regenerateSchedule(for user: User, modelContext: ModelContext) {
        let existingSlots = user.scheduleSlots ?? []
        let logs = user.intakeLogs ?? []

        // Identify slots with historical logs (slots we must preserve IDs for)
        let slotIdsWithHistory = Set(
            logs.filter { !$0.supplementIdsTaken.isEmpty }
                .map { $0.scheduleSlotId }
        )

        // Create lookup: (time, context) -> existing slot info
        var slotIdLookup: [String: UUID] = [:]
        var slotInfoByIdLookup: [UUID: ScheduleSlot] = [:]
        for slot in existingSlots {
            let key = "\(slot.time)-\(slot.context.rawValue)"
            slotIdLookup[key] = slot.id
            slotInfoByIdLookup[slot.id] = slot
        }

        // Generate new schedule with only ACTIVE (non-archived) supplements
        let activeSupplements = (user.supplements ?? []).filter { !$0.isArchived }
        let newSlots = schedulingService.generateSchedule(
            supplements: activeSupplements,
            breakfastTime: user.breakfastTime,
            lunchTime: user.lunchTime,
            dinnerTime: user.dinnerTime,
            skipBreakfast: user.skipBreakfast
        )

        // Track which historical slot IDs are covered by new slots
        var coveredHistoricalSlotIds = Set<UUID>()

        // Preserve slot IDs where time+context match
        for slot in newSlots {
            let key = "\(slot.time)-\(slot.context.rawValue)"
            if let existingId = slotIdLookup[key] {
                slot.id = existingId
                if slotIdsWithHistory.contains(existingId) {
                    coveredHistoricalSlotIds.insert(existingId)
                }
            }
        }

        // Find historical slots that aren't covered by new slots (orphaned historical slots)
        let orphanedHistoricalSlotIds = slotIdsWithHistory.subtracting(coveredHistoricalSlotIds)

        // Delete existing slots
        for slot in existingSlots {
            modelContext.delete(slot)
        }

        // Insert new slots
        for slot in newSlots {
            slot.user = user
            modelContext.insert(slot)
        }

        // Re-create orphaned historical slots with empty supplementIds (for historical reference)
        for slotId in orphanedHistoricalSlotIds {
            if let oldSlot = slotInfoByIdLookup[slotId] {
                let archivedSlot = ScheduleSlot(
                    id: slotId,  // Keep same ID for log references
                    time: oldSlot.time,
                    context: oldSlot.context,
                    supplementIds: [],  // Empty - for historical reference only
                    explanation: oldSlot.explanation,
                    createdAt: oldSlot.createdAt,
                    sortOrder: 999  // Put at end
                )
                archivedSlot.user = user
                modelContext.insert(archivedSlot)
            }
        }

        try? modelContext.save()
    }
}
