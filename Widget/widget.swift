//
//  widget.swift
//  widget
//
//  Pillo Widget - Shows supplement progress and upcoming doses
//

import WidgetKit
import SwiftUI

// MARK: - Shared Container (for reading data from main app)
struct SharedContainer {
    static let appGroupIdentifier = "group.com.suplo.shared"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    // MARK: - Keys
    private enum Keys {
        static let todayProgress = "todayProgress"
        static let todayTotal = "todayTotal"
        static let currentStreak = "currentStreak"
        static let nextDoseTime = "nextDoseTime"
        static let nextDoseSupplements = "nextDoseSupplements"
        static let nextDoseContext = "nextDoseContext"
        static let lastUpdated = "lastUpdated"
        static let selectedTheme = "selectedTheme"
    }

    // MARK: - Today Progress
    static func getTodayProgress() -> (completed: Int, total: Int) {
        let completed = sharedDefaults?.integer(forKey: Keys.todayProgress) ?? 0
        let total = sharedDefaults?.integer(forKey: Keys.todayTotal) ?? 0
        return (completed, total)
    }

    // MARK: - Streak
    static func getStreak() -> Int {
        sharedDefaults?.integer(forKey: Keys.currentStreak) ?? 0
    }

    // MARK: - Next Dose
    static func getNextDose() -> (time: String?, supplements: [String], context: String?) {
        let time = sharedDefaults?.string(forKey: Keys.nextDoseTime)
        let supplements = sharedDefaults?.stringArray(forKey: Keys.nextDoseSupplements) ?? []
        let context = sharedDefaults?.string(forKey: Keys.nextDoseContext)
        return (time, supplements, context)
    }

    // MARK: - Last Updated
    static func getLastUpdated() -> Date? {
        sharedDefaults?.object(forKey: Keys.lastUpdated) as? Date
    }

    // MARK: - Theme
    static func isDarkMode() -> Bool {
        let savedValue = sharedDefaults?.string(forKey: Keys.selectedTheme) ?? "light"
        return savedValue == "dark"
    }
}

// MARK: - Widget Data Model
struct WidgetData {
    let completed: Int
    let total: Int
    let streak: Int
    let nextDoseTime: String?
    let nextDoseSupplements: [String]
    let nextDoseContext: String?
    let lastUpdated: Date
    let isDarkMode: Bool

    var progressPercentage: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var isComplete: Bool {
        total > 0 && completed >= total
    }

    static var placeholder: WidgetData {
        WidgetData(
            completed: 2,
            total: 5,
            streak: 7,
            nextDoseTime: "8:00 AM",
            nextDoseSupplements: ["Vitamin D", "Fish Oil"],
            nextDoseContext: "With breakfast",
            lastUpdated: Date(),
            isDarkMode: false
        )
    }

    static func fromSharedContainer() -> WidgetData {
        let progress = SharedContainer.getTodayProgress()
        let nextDose = SharedContainer.getNextDose()

        return WidgetData(
            completed: progress.completed,
            total: progress.total,
            streak: SharedContainer.getStreak(),
            nextDoseTime: nextDose.time,
            nextDoseSupplements: nextDose.supplements,
            nextDoseContext: nextDose.context,
            lastUpdated: SharedContainer.getLastUpdated() ?? Date(),
            isDarkMode: SharedContainer.isDarkMode()
        )
    }
}

// MARK: - Timeline Entry
struct PilloEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Timeline Provider
struct PilloProvider: TimelineProvider {
    func placeholder(in context: Context) -> PilloEntry {
        PilloEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (PilloEntry) -> Void) {
        let entry = PilloEntry(date: Date(), data: WidgetData.fromSharedContainer())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PilloEntry>) -> Void) {
        let currentDate = Date()
        let data = WidgetData.fromSharedContainer()
        let entry = PilloEntry(date: currentDate, data: data)

        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Small Widget View
struct SmallWidgetView: View {
    let entry: PilloEntry

    private var textColor: Color {
        entry.data.isDarkMode ? .white : .black
    }

    private var secondaryTextColor: Color {
        entry.data.isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6)
    }

    private var backgroundColor: Color {
        entry.data.isDarkMode ? Color.black : Color.white
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let time = entry.data.nextDoseTime {
                Text(time)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(textColor)

                if let supplement = entry.data.nextDoseSupplements.first {
                    Text(supplement)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(textColor)
                        .lineLimit(1)
                }

                if let context = entry.data.nextDoseContext {
                    Text(context)
                        .font(.system(size: 12))
                        .foregroundColor(secondaryTextColor)
                }
            } else if entry.data.isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: "4ADE80"))

                Text("All done!")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textColor)

                Text("Great job today")
                    .font(.system(size: 12))
                    .foregroundColor(secondaryTextColor)
            } else {
                Text("No doses")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textColor)

                Text("scheduled")
                    .font(.system(size: 14))
                    .foregroundColor(secondaryTextColor)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .containerBackground(for: .widget) {
            backgroundColor
        }
    }
}

// MARK: - Medium Widget View
struct MediumWidgetView: View {
    let entry: PilloEntry

    private var textColor: Color {
        entry.data.isDarkMode ? .white : .black
    }

    private var secondaryTextColor: Color {
        entry.data.isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6)
    }

    private var tertiaryTextColor: Color {
        entry.data.isDarkMode ? Color.white.opacity(0.5) : Color.black.opacity(0.5)
    }

    private var backgroundColor: Color {
        entry.data.isDarkMode ? Color.black : Color.white
    }

    private var dividerColor: Color {
        entry.data.isDarkMode ? Color.white.opacity(0.2) : Color.black.opacity(0.1)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Left side - Progress
            VStack(alignment: .leading, spacing: 8) {
                // Progress circle
                ZStack {
                    Circle()
                        .stroke(dividerColor, lineWidth: 6)
                        .frame(width: 50, height: 50)

                    Circle()
                        .trim(from: 0, to: entry.data.progressPercentage)
                        .stroke(Color(hex: "4ADE80"), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))

                    Text("\(entry.data.completed)/\(entry.data.total)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(textColor)
                }

                Text("\(Int(entry.data.progressPercentage * 100))%")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(secondaryTextColor)

                if entry.data.streak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "FBBF24"))
                        Text("\(entry.data.streak) days")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "FBBF24"))
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(dividerColor)
                .frame(width: 1)
                .padding(.vertical, 8)

            // Right side - Upcoming
            VStack(alignment: .leading, spacing: 6) {
                Text("UPCOMING")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(tertiaryTextColor)
                    .tracking(1)

                if let time = entry.data.nextDoseTime {
                    Text(time)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(textColor)

                    let supplementsText = entry.data.nextDoseSupplements.prefix(2).joined(separator: ", ")
                    Text(supplementsText)
                        .font(.system(size: 13))
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(2)

                    if let context = entry.data.nextDoseContext {
                        Text(context)
                            .font(.system(size: 11))
                            .foregroundColor(tertiaryTextColor)
                    }
                } else if entry.data.isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "4ADE80"))

                    Text("All doses complete!")
                        .font(.system(size: 13))
                        .foregroundColor(secondaryTextColor)
                } else {
                    Text("No upcoming doses")
                        .font(.system(size: 13))
                        .foregroundColor(secondaryTextColor)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .containerBackground(for: .widget) {
            backgroundColor
        }
    }
}

// MARK: - Widget Entry View
struct PilloWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: PilloEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration
struct PilloWidget: Widget {
    let kind: String = "PilloWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PilloProvider()) { entry in
            PilloWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Pillo")
        .description("Track your supplement schedule")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Previews
#Preview("Small", as: .systemSmall) {
    PilloWidget()
} timeline: {
    PilloEntry(date: .now, data: .placeholder)
}

#Preview("Medium", as: .systemMedium) {
    PilloWidget()
} timeline: {
    PilloEntry(date: .now, data: .placeholder)
}
