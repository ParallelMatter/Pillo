import SwiftUI
import SwiftData

struct MainTabView: View {
    @Binding var selectedTab: Int

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }
                .tag(0)

            VitaminsListView()
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
    }
}

#Preview {
    MainTabView(selectedTab: .constant(0))
        .preferredColorScheme(.dark)
        .modelContainer(for: [User.self, Supplement.self, ScheduleSlot.self, IntakeLog.self], inMemory: true)
}
