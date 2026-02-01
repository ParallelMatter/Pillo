import SwiftUI
import SwiftData

struct MainTabView: View {
    @Binding var selectedTab: Int
    @State private var showRoutineHint = false

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }
                .tag(0)

            SupplementsListView()
                .tabItem {
                    Label("Routine", systemImage: "pill.fill")
                }
                .tag(1)

            GoalsListView()
                .tabItem {
                    Label("Goals", systemImage: "target")
                }
                .tag(2)

            LearnView()
                .tabItem {
                    Label("Learn", systemImage: "book.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(Theme.textPrimary)
        .overlay {
            if showRoutineHint {
                TabTooltip(
                    text: "Add more anytime here",
                    tabIndex: 1,
                    totalTabs: 5,
                    onDismiss: dismissHint
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            checkAndShowHint()
        }
    }

    private func checkAndShowHint() {
        guard !SharedContainer.hasSeenRoutineHint() else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showRoutineHint = true
            }
            // Auto-dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                if showRoutineHint {
                    dismissHint()
                }
            }
        }
    }

    private func dismissHint() {
        withAnimation(.easeOut(duration: 0.4)) {
            showRoutineHint = false
        }
        SharedContainer.setRoutineHintSeen()
    }
}

#Preview {
    MainTabView(selectedTab: .constant(0))
        .preferredColorScheme(.dark)
        .modelContainer(for: [User.self, Supplement.self, ScheduleSlot.self, IntakeLog.self], inMemory: true)
}
