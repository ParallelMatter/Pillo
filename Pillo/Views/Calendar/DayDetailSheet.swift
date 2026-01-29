import SwiftUI
import SwiftData

struct DayDetailSheet: View {
    let date: Date
    let dayData: DayData
    let intakeLogs: [IntakeLog]
    let slots: [ScheduleSlot]
    let supplements: [Supplement]

    @Environment(\.dismiss) private var dismiss

    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }

    private var dateString: String {
        StreakService.dateString(for: date)
    }

    /// Get slots that are active for this specific date AND have supplements that existed then
    private var activeSlotsForDate: [ScheduleSlot] {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        let isHistoricalDate = normalizedDate < calendar.startOfDay(for: Date())

        return slots.filter { slot in
            guard slot.isActiveOn(date: date) else { return false }

            // For past dates, only include if at least one supplement existed on that date
            if isHistoricalDate {
                let slotSupplementIds = Set(slot.supplementIds)
                let supplementsInSlot = supplements.filter { slotSupplementIds.contains($0.id) }
                let anyExistedOnDate = supplementsInSlot.contains { supplement in
                    calendar.startOfDay(for: supplement.createdAt) <= normalizedDate
                }
                return anyExistedOnDate
            }
            return true
        }
    }

    /// Get logs for this specific date
    private var logsForDate: [IntakeLog] {
        let slotIds = Set(activeSlotsForDate.map { $0.id })
        return intakeLogs.filter { $0.date == dateString && slotIds.contains($0.scheduleSlotId) }
    }

    /// Get slot details for the day
    /// For historical display, we include archived supplements if they were taken that day
    private var slotDetails: [(slot: ScheduleSlot, log: IntakeLog?, supplements: [Supplement], deletedTakenNames: [String], deletedSkippedCount: Int)] {
        activeSlotsForDate.sorted { $0.sortOrder < $1.sortOrder }.compactMap { slot in
            let log = logsForDate.first { $0.scheduleSlotId == slot.id }

            // For historical display, get supplements from either:
            // 1. Current slot supplementIds (for current/active supplements)
            // 2. Log's supplementIdsTaken (for archived supplements that were taken)
            var relevantSupplementIds = Set(slot.supplementIds)
            if let log = log {
                relevantSupplementIds.formUnion(log.supplementIdsTaken)
                relevantSupplementIds.formUnion(log.supplementIdsSkipped)
            }

            let existingSupplementIds = Set(supplements.map { $0.id })
            let existingSupplementNames = Set(supplements.map { $0.name })

            // IDs from the log (these have historical records, show regardless of creation date)
            let loggedIds: Set<UUID>
            if let log = log {
                loggedIds = Set(log.supplementIdsTaken).union(Set(log.supplementIdsSkipped))
            } else {
                loggedIds = []
            }

            // Filter supplements: show if in log OR (in slot AND existed on this date)
            let calendar = Calendar.current
            let normalizedDate = calendar.startOfDay(for: date)
            let isHistoricalDate = normalizedDate < calendar.startOfDay(for: Date())

            let slotSupplements = supplements.filter { supplement in
                guard relevantSupplementIds.contains(supplement.id) else { return false }

                // Always show supplements that were logged (taken/skipped)
                if loggedIds.contains(supplement.id) {
                    return true
                }

                // For historical dates, only show supplements that existed then
                if isHistoricalDate {
                    return calendar.startOfDay(for: supplement.createdAt) <= normalizedDate
                }

                return true
            }

            // Get names of deleted supplements from stored history
            var deletedTakenNames: [String] = []
            var deletedSkippedCount = 0
            if let log = log {
                // Use stored names for taken supplements that no longer exist
                deletedTakenNames = log.takenSupplementNames.filter { !existingSupplementNames.contains($0) }
                // If no stored names, fall back to counting
                let deletedTakenCount = log.supplementIdsTaken.filter { !existingSupplementIds.contains($0) }.count
                if deletedTakenNames.isEmpty && deletedTakenCount > 0 {
                    deletedTakenNames = (0..<deletedTakenCount).map { _ in "Unknown supplement" }
                }
                deletedSkippedCount = log.supplementIdsSkipped.filter { !existingSupplementIds.contains($0) }.count
            }

            // Show slots that have supplements, logs, OR deleted supplement records
            if slotSupplements.isEmpty && log == nil && deletedTakenNames.isEmpty && deletedSkippedCount == 0 {
                return nil
            }

            return (slot: slot, log: log, supplements: slotSupplements, deletedTakenNames: deletedTakenNames, deletedSkippedCount: deletedSkippedCount)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.spacingLG) {
                        // Date header
                        VStack(alignment: .leading, spacing: Theme.spacingSM) {
                            Text(dateTitle.uppercased())
                                .font(Theme.titleFont)
                                .tracking(1)
                                .foregroundColor(Theme.textPrimary)

                            // Summary
                            HStack(spacing: Theme.spacingSM) {
                                statusIcon
                                Text(summaryText)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }

                        Divider()
                            .background(Theme.border)

                        // Slot breakdown
                        if !activeSlotsForDate.isEmpty || !slotDetails.isEmpty {
                            VStack(spacing: Theme.spacingMD) {
                                ForEach(slotDetails, id: \.slot.id) { detail in
                                    SlotDetailCard(
                                        slot: detail.slot,
                                        log: detail.log,
                                        supplements: detail.supplements,
                                        deletedTakenNames: detail.deletedTakenNames,
                                        deletedSkippedCount: detail.deletedSkippedCount
                                    )
                                }
                            }
                        } else {
                            Text("No schedule configured for this day")
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textSecondary)
                        }

                        Spacer(minLength: Theme.spacingXL)
                    }
                    .padding(Theme.spacingLG)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textPrimary)
                }
            }
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch dayData.status {
        case .complete:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Theme.success)
        case .partial:
            Image(systemName: "circle.lefthalf.filled")
                .foregroundColor(Theme.warning)
        case .missed:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(Theme.border)
        case .today, .future:
            Image(systemName: "circle")
                .foregroundColor(Theme.textSecondary)
        }
    }

    private var summaryText: String {
        let total = dayData.totalCount
        let taken = dayData.takenCount

        if total == 0 {
            return "No doses scheduled"
        }

        switch dayData.status {
        case .complete:
            return "All \(total) doses completed"
        case .partial:
            return "\(taken) of \(total) completed"
        case .missed:
            return "0 of \(total) completed"
        case .today:
            return "\(taken) of \(total) completed so far"
        case .future:
            return "\(total) doses scheduled"
        }
    }
}

struct SlotDetailCard: View {
    let slot: ScheduleSlot
    let log: IntakeLog?
    let supplements: [Supplement]
    var deletedTakenNames: [String] = []
    var deletedSkippedCount: Int = 0

    private var takenCount: Int {
        (log?.supplementIdsTaken.count ?? 0)
    }

    private var skippedCount: Int {
        (log?.supplementIdsSkipped.count ?? 0)
    }

    private var totalCount: Int {
        supplements.count + deletedTakenNames.count + deletedSkippedCount
    }

    private var slotStatus: SlotStatus {
        guard let log = log else { return .upcoming }

        let takenIds = Set(log.supplementIdsTaken)
        let skippedIds = Set(log.supplementIdsSkipped)
        let allIds = Set(supplements.map { $0.id })

        if takenIds.isSuperset(of: allIds) && !allIds.isEmpty {
            return .taken
        }
        if skippedIds.isSuperset(of: allIds) && !allIds.isEmpty {
            return .skipped
        }
        if !takenIds.isEmpty || !skippedIds.isEmpty {
            return .partial
        }
        return .upcoming
    }

    private var statusColor: Color {
        switch slotStatus {
        case .taken:
            return Theme.success
        case .partial:
            return Theme.accent
        case .skipped:
            return Theme.warning
        case .upcoming, .missed:
            return Theme.border
        }
    }

    private var statusText: String {
        switch slotStatus {
        case .taken:
            return "Taken"
        case .partial:
            return "\(takenCount)/\(totalCount)"
        case .skipped:
            return "Skipped"
        case .upcoming:
            return "Pending"
        case .missed:
            return "Missed"
        }
    }

    private var timeText: String? {
        guard let log = log, let takenAt = log.takenAt else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: takenAt)
    }

    private func isSupplementTaken(_ supplement: Supplement) -> Bool {
        log?.supplementIdsTaken.contains(supplement.id) ?? false
    }

    private func isSupplementSkipped(_ supplement: Supplement) -> Bool {
        log?.supplementIdsSkipped.contains(supplement.id) ?? false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            // Slot header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(slot.displayTime)
                        .font(Theme.bodyFont.weight(.semibold))
                        .foregroundColor(Theme.textPrimary)

                    Text(slot.context.displayName)
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                // Status badge
                HStack(spacing: Theme.spacingXS) {
                    Text(statusText)
                        .font(Theme.captionFont.weight(.medium))
                        .foregroundColor(statusColor)

                    if let time = timeText {
                        Text("at \(time)")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }

            // Supplements in this slot with individual status
            if !supplements.isEmpty || !deletedTakenNames.isEmpty || deletedSkippedCount > 0 {
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    ForEach(supplements) { supplement in
                        let isTaken = isSupplementTaken(supplement)
                        let isSkipped = isSupplementSkipped(supplement)
                        let itemColor = isTaken ? Theme.success : (isSkipped ? Theme.warning : Theme.border)

                        HStack(spacing: Theme.spacingSM) {
                            Image(systemName: isTaken ? "checkmark.circle.fill" : (isSkipped ? "xmark.circle" : "circle"))
                                .font(.system(size: 12))
                                .foregroundColor(itemColor)

                            Text(supplement.name)
                                .font(Theme.captionFont)
                                .foregroundColor(isTaken || isSkipped ? Theme.textSecondary : Theme.textPrimary)
                                .strikethrough(isTaken || isSkipped)

                            if !supplement.displayDosage.isEmpty {
                                Text(supplement.displayDosage)
                                    .font(Theme.captionFont)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                    }

                    // Show deleted supplements that were taken (with names if available)
                    ForEach(Array(deletedTakenNames.enumerated()), id: \.offset) { _, name in
                        HStack(spacing: Theme.spacingSM) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.success)

                            Text(name)
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                                .strikethrough(true)

                            Text("(removed)")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                                .italic()
                        }
                    }

                    // Show deleted supplements that were skipped (count only, no names stored)
                    if deletedSkippedCount > 0 {
                        HStack(spacing: Theme.spacingSM) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.warning)

                            Text("\(deletedSkippedCount) removed supplement\(deletedSkippedCount == 1 ? "" : "s") skipped")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                                .italic()
                        }
                    }
                }
                .padding(.top, Theme.spacingXS)
            }
        }
        .padding(Theme.spacingMD)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusSM)
    }
}

#Preview {
    DayDetailSheet(
        date: Date(),
        dayData: DayData(date: Date(), status: .partial, takenCount: 2, totalCount: 3),
        intakeLogs: [],
        slots: [],
        supplements: []
    )
    .preferredColorScheme(.dark)
}
