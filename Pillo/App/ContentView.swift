import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @Binding var selectedTab: Int

    var body: some View {
        Group {
            if users.isEmpty {
                OnboardingContainerView()
            } else {
                MainTabView(selectedTab: $selectedTab)
            }
        }
    }
}

#Preview {
    ContentView(selectedTab: .constant(0))
        .modelContainer(for: [User.self, Supplement.self, ScheduleSlot.self, IntakeLog.self], inMemory: true)
}
