import SwiftUI
import SwiftData
import UIKit

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @Query private var supplements: [Supplement]
    @Query private var intakeLogs: [IntakeLog]
    @State private var viewModel = TodayViewModel()
    @State private var refreshID = UUID()
    @State private var showingCalendar = false

    private var user: User? { users.first }
    private var slots: [ScheduleSlot] {
        // Filter out empty/archived slots and slots not active today
        let today = Date()
        return (user?.scheduleSlots ?? [])
            .filter { !$0.supplementIds.isEmpty && $0.isActiveOn(date: today) }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Get set of supplement IDs that are marked as taken for a slot today
    private func getSupplementsTaken(for slot: ScheduleSlot) -> Set<UUID> {
        let todayString = IntakeLog.todayDateString()
        guard let log = intakeLogs.first(where: { $0.scheduleSlotId == slot.id && $0.date == todayString }) else {
            return []
        }
        return Set(log.supplementIdsTaken)
    }

    /// Get set of supplement IDs that are marked as skipped for a slot today
    private func getSupplementsSkipped(for slot: ScheduleSlot) -> Set<UUID> {
        let todayString = IntakeLog.todayDateString()
        guard let log = intakeLogs.first(where: { $0.scheduleSlotId == slot.id && $0.date == todayString }) else {
            return []
        }
        return Set(log.supplementIdsSkipped)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if let user = user {
                    ScrollView {
                        VStack(spacing: Theme.spacingLG) {
                            // Header
                            TodayHeader()

                            // Streak Card
                            StreakCard(
                                streak: viewModel.calculateStreak(slots: slots, logs: intakeLogs),
                                sevenDayHistory: viewModel.getSevenDayHistory(slots: slots, logs: intakeLogs),
                                onTap: {
                                    showingCalendar = true
                                }
                            )
                            .padding(.horizontal, Theme.spacingLG)
                            .sheet(isPresented: $showingCalendar) {
                                CalendarSheet(
                                    intakeLogs: Array(intakeLogs),
                                    slots: slots,
                                    supplements: Array(supplements)
                                )
                            }

                            // Progress Card
                            ProgressCard(
                                stats: viewModel.getCompletionStats(slots: slots, logs: intakeLogs)
                            )
                            .padding(.horizontal, Theme.spacingLG)

                            // Timeline
                            VStack(spacing: Theme.spacingMD) {
                                ForEach(slots) { slot in
                                    let slotSupplements = viewModel.getSupplementsForSlot(slot, allSupplements: supplements)
                                    let supplementsTaken = getSupplementsTaken(for: slot)
                                    let supplementsSkipped = getSupplementsSkipped(for: slot)

                                    TimeSlotCard(
                                        slot: slot,
                                        supplements: slotSupplements,
                                        status: viewModel.getSlotStatus(slot: slot, logs: intakeLogs),
                                        supplementsTaken: supplementsTaken,
                                        supplementsSkipped: supplementsSkipped,
                                        onSupplementToggle: { supplementId in
                                            withAnimation {
                                                // Toggle: if taken, undo; if not taken, mark as taken
                                                if supplementsTaken.contains(supplementId) {
                                                    viewModel.undoSupplementStatus(supplementId: supplementId, slot: slot, modelContext: modelContext, user: user)
                                                } else {
                                                    viewModel.markSupplementAsTaken(supplementId: supplementId, slot: slot, modelContext: modelContext, user: user)
                                                }
                                                viewModel.updateWidgetData(slots: slots, logs: user.intakeLogs ?? [], supplements: supplements)
                                            }
                                        },
                                        onMarkAllTaken: {
                                            withAnimation {
                                                viewModel.markAsTaken(slot: slot, modelContext: modelContext, user: user)
                                                viewModel.updateWidgetData(slots: slots, logs: user.intakeLogs ?? [], supplements: supplements)
                                            }
                                        },
                                        onMarkAllSkipped: {
                                            withAnimation {
                                                viewModel.markAsSkipped(slot: slot, modelContext: modelContext, user: user)
                                                viewModel.updateWidgetData(slots: slots, logs: user.intakeLogs ?? [], supplements: supplements)
                                            }
                                        },
                                        onUndo: {
                                            withAnimation {
                                                viewModel.undoStatus(slot: slot, modelContext: modelContext, user: user)
                                                viewModel.updateWidgetData(slots: slots, logs: user.intakeLogs ?? [], supplements: supplements)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, Theme.spacingLG)
                            .padding(.bottom, Theme.spacingXXL)
                        }
                    }
                    .id(refreshID)
                } else {
                    Text("No schedule found")
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .onAppear {
                if let _ = user {
                    viewModel.updateWidgetData(slots: slots, logs: intakeLogs, supplements: supplements)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .appDidBecomeActive)) { _ in
                refreshID = UUID()
                if let _ = user {
                    viewModel.updateWidgetData(slots: slots, logs: intakeLogs, supplements: supplements)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                refreshID = UUID()
                if let _ = user {
                    viewModel.updateWidgetData(slots: slots, logs: intakeLogs, supplements: supplements)
                }
            }
        }
    }
}

struct TodayHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingXS) {
            Text("TODAY")
                .font(Theme.headerFont)
                .tracking(2)
                .foregroundColor(Theme.textSecondary)

            Text(Date(), format: .dateTime.month(.wide).day())
                .font(Theme.displayFont)
                .foregroundColor(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.spacingLG)
        .padding(.top, Theme.spacingMD)
    }
}

struct ProgressCard: View {
    let stats: (completed: Int, total: Int)

    private var progress: Double {
        guard stats.total > 0 else { return 0 }
        return Double(stats.completed) / Double(stats.total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMD) {
            Text("\(stats.completed) of \(stats.total) completed")
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textPrimary)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Theme.border)
                        .frame(height: 4)
                        .cornerRadius(2)

                    Rectangle()
                        .fill(Theme.success)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 4)

            Text("\(Int(progress * 100))%")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
        }
        .cardStyle()
    }
}

#Preview {
    TodayView()
        .preferredColorScheme(.light)
        .modelContainer(for: [User.self, Supplement.self, ScheduleSlot.self, IntakeLog.self], inMemory: true)
}

// MARK: - Custom Notification Name
extension Notification.Name {
    static let appDidBecomeActive = Notification.Name("appDidBecomeActive")
}
