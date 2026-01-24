import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @State private var themeManager = ThemeManager.shared

    private var user: User? { users.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.spacingLG) {
                        // Header
                        Text("SETTINGS")
                            .font(Theme.headerFont)
                            .tracking(2)
                            .foregroundColor(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Theme.spacingLG)
                            .padding(.top, Theme.spacingMD)

                        if let user = user {
                            // Schedule Section
                            SettingsSection(title: "SCHEDULE") {
                                MealTimeRow(
                                    title: "Breakfast time",
                                    time: user.breakfastTime,
                                    user: user,
                                    meal: .breakfast,
                                    modelContext: modelContext
                                )

                                Divider().background(Theme.border)

                                MealTimeRow(
                                    title: "Lunch time",
                                    time: user.lunchTime,
                                    user: user,
                                    meal: .lunch,
                                    modelContext: modelContext
                                )

                                Divider().background(Theme.border)

                                MealTimeRow(
                                    title: "Dinner time",
                                    time: user.dinnerTime,
                                    user: user,
                                    meal: .dinner,
                                    modelContext: modelContext
                                )

                                Divider().background(Theme.border)

                                ToggleRow(
                                    title: "I skip breakfast",
                                    isOn: Binding(
                                        get: { user.skipBreakfast },
                                        set: {
                                            user.skipBreakfast = $0
                                            regenerateSchedule(for: user)
                                        }
                                    )
                                )
                            }

                            // Notifications Section
                            SettingsSection(title: "NOTIFICATIONS") {
                                ToggleRow(
                                    title: "Reminder notifications",
                                    isOn: Binding(
                                        get: { user.notificationsEnabled },
                                        set: {
                                            user.notificationsEnabled = $0
                                            updateNotifications(for: user)
                                        }
                                    )
                                )

                                if user.notificationsEnabled {
                                    Divider().background(Theme.border)

                                    PickerRow(
                                        title: "Reminder sound",
                                        selection: Binding(
                                            get: { user.notificationSound },
                                            set: {
                                                user.notificationSound = $0
                                                updateNotifications(for: user)
                                            }
                                        ),
                                        options: ["subtle", "standard", "none"]
                                    )

                                    Divider().background(Theme.border)

                                    PickerRow(
                                        title: "Remind me early",
                                        selection: Binding(
                                            get: { "\(user.notificationAdvanceMinutes) min" },
                                            set: {
                                                let minutes = Int($0.replacingOccurrences(of: " min", with: "")) ?? 5
                                                user.notificationAdvanceMinutes = minutes
                                                updateNotifications(for: user)
                                            }
                                        ),
                                        options: ["0 min", "5 min", "10 min", "15 min"]
                                    )
                                }
                            }

                            // Appearance Section
                            SettingsSection(title: "APPEARANCE") {
                                ToggleRow(
                                    title: "Dark mode",
                                    isOn: Binding(
                                        get: { themeManager.themeMode == .dark },
                                        set: { isDark in
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                themeManager.themeMode = isDark ? .dark : .light
                                            }
                                        }
                                    )
                                )
                            }

                            // Data Section
                            SettingsSection(title: "DATA") {
                                NavigationRow(title: "Export my data") {
                                    // TODO: Implement data export
                                }

                                Divider().background(Theme.border)

                                NavigationRow(title: "Connect Apple Health") {
                                    // TODO: Implement HealthKit integration
                                }
                            }

                            // About Section
                            SettingsSection(title: "ABOUT") {
                                NavigationRow(title: "How scheduling works") {
                                    // TODO: Show scheduling explanation
                                }

                                Divider().background(Theme.border)

                                NavigationRow(title: "Privacy policy") {
                                    // TODO: Open privacy policy
                                }

                                Divider().background(Theme.border)

                                NavigationRow(title: "Terms of service") {
                                    // TODO: Open terms
                                }

                                Divider().background(Theme.border)

                                NavigationRow(title: "Send feedback") {
                                    // TODO: Open feedback
                                }

                                Divider().background(Theme.border)

                                NavigationRow(title: "Rate Pillo") {
                                    // TODO: Open App Store
                                }
                            }

                            // Version
                            Text("Version 1.0.0")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                                .padding(.top, Theme.spacingMD)
                        }
                    }
                    .padding(.bottom, Theme.spacingXXL)
                }
            }
        }
    }

    private func regenerateSchedule(for user: User) {
        let schedulingService = SchedulingService.shared
        let existingSlots = user.scheduleSlots ?? []

        // Create lookup: (time, context) -> existing slot ID
        var slotIdLookup: [String: UUID] = [:]
        for slot in existingSlots {
            let key = "\(slot.time)-\(slot.context.rawValue)"
            slotIdLookup[key] = slot.id
        }

        // Delete existing slots
        for slot in existingSlots {
            modelContext.delete(slot)
        }

        // Generate new schedule
        let supplements = user.supplements ?? []
        let newSlots = schedulingService.generateSchedule(
            supplements: supplements,
            breakfastTime: user.breakfastTime,
            lunchTime: user.lunchTime,
            dinnerTime: user.dinnerTime,
            skipBreakfast: user.skipBreakfast
        )

        // Preserve slot IDs where time+context match
        for slot in newSlots {
            let key = "\(slot.time)-\(slot.context.rawValue)"
            if let existingId = slotIdLookup[key] {
                slot.id = existingId
            }
            slot.user = user
            modelContext.insert(slot)
        }

        try? modelContext.save()
        updateNotifications(for: user)
    }

    private func updateNotifications(for user: User) {
        let notificationService = NotificationService.shared

        if user.notificationsEnabled {
            notificationService.scheduleNotifications(
                for: user.scheduleSlots ?? [],
                supplements: user.supplements ?? [],
                advanceMinutes: user.notificationAdvanceMinutes,
                sound: user.notificationSound
            )
        } else {
            notificationService.cancelAllNotifications()
        }

        try? modelContext.save()
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            Text(title)
                .font(Theme.headerFont)
                .tracking(1)
                .foregroundColor(Theme.textSecondary)
                .padding(.horizontal, Theme.spacingLG)

            VStack(spacing: 0) {
                content
            }
            .background(Theme.surface)
            .cornerRadius(Theme.cornerRadiusMD)
            .padding(.horizontal, Theme.spacingLG)
        }
    }
}

enum MealType {
    case breakfast, lunch, dinner
}

struct MealTimeRow: View {
    let title: String
    let time: String
    let user: User
    let meal: MealType
    let modelContext: ModelContext

    @State private var showingPicker = false
    @State private var selectedTime: Date = Date()

    var body: some View {
        Button(action: {
            showingPicker = true
        }) {
            HStack {
                Text(title)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Text(formattedTime)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textSecondary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(Theme.spacingMD)
        }
        .sheet(isPresented: $showingPicker) {
            TimePickerSheet(
                title: title,
                selectedTime: $selectedTime,
                onSave: {
                    saveTime()
                    showingPicker = false
                }
            )
            .presentationDetents([.height(300)])
        }
        .onAppear {
            selectedTime = parseTime(time)
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let date = formatter.date(from: time) else { return time }

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "h:mm a"
        return outputFormatter.string(from: date)
    }

    private func parseTime(_ timeString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString) ?? Date()
    }

    private func formatTimeForStorage(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func saveTime() {
        let newTime = formatTimeForStorage(selectedTime)

        switch meal {
        case .breakfast:
            user.breakfastTime = newTime
        case .lunch:
            user.lunchTime = newTime
        case .dinner:
            user.dinnerTime = newTime
        }

        // Regenerate schedule
        let schedulingService = SchedulingService.shared

        for slot in user.scheduleSlots ?? [] {
            modelContext.delete(slot)
        }

        let supplements = user.supplements ?? []
        let newSlots = schedulingService.generateSchedule(
            supplements: supplements,
            breakfastTime: user.breakfastTime,
            lunchTime: user.lunchTime,
            dinnerTime: user.dinnerTime,
            skipBreakfast: user.skipBreakfast
        )

        for slot in newSlots {
            slot.user = user
            modelContext.insert(slot)
        }

        try? modelContext.save()
    }
}

struct TimePickerSheet: View {
    let title: String
    @Binding var selectedTime: Date
    let onSave: () -> Void
    private let themeManager = ThemeManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack {
                    DatePicker(
                        "",
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(themeManager.themeMode.colorScheme)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .foregroundColor(Theme.textPrimary)
                }
            }
        }
    }
}

struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(Theme.success)
                .labelsHidden()
        }
        .padding(Theme.spacingMD)
    }
}

struct PickerRow: View {
    let title: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        HStack {
            Text(title)
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option.capitalized).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.textSecondary)
        }
        .padding(Theme.spacingMD)
    }
}

struct NavigationRow: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(Theme.spacingMD)
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
        .modelContainer(for: [User.self, Supplement.self, ScheduleSlot.self, IntakeLog.self], inMemory: true)
}
