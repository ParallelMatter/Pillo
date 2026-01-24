# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Pillo is an iOS health supplement tracking app built with SwiftUI and SwiftData. It features an intelligent scheduling algorithm that avoids supplement interactions, a home screen widget, and local notifications with snooze actions.

**Stack:** Swift 5.0, SwiftUI, SwiftData, WidgetKit, UserNotifications, AVFoundation (barcode scanning)
**Minimum iOS:** 17+ (required for SwiftData)

## Build Commands

```bash
# Build the app
xcodebuild -project Pillo.xcodeproj -scheme Pillo -configuration Debug

# Build for release
xcodebuild -project Pillo.xcodeproj -scheme Pillo -configuration Release

# Build widget extension
xcodebuild -project Pillo.xcodeproj -scheme Widget -configuration Release

# Run tests
xcodebuild test -project Pillo.xcodeproj -scheme Pillo

# Clean build
xcodebuild clean -project Pillo.xcodeproj
```

## Architecture

### Data Flow Pattern
Models (@Model) → ViewModels (@Observable) → Views (@Query for reads, modelContext for writes)

### Key Directories
- `App/` - Entry point (PilloApp.swift), SwiftData container setup, notification delegation
- `Models/` - SwiftData entities: User, Supplement, ScheduleSlot, IntakeLog, SupplementReference
- `Views/` - SwiftUI views organized by feature (Today, Supplements, Goals, Learn, Settings, Onboarding, Calendar)
- `ViewModels/` - @Observable state managers (TodayViewModel, SupplementsViewModel, OnboardingViewModel)
- `Services/` - Business logic singletons with `shared` pattern
- `Widget/` - WidgetKit home screen widget

### Core Services
- **SchedulingService** - Core scheduling algorithm: assigns supplements to 7 daily time slots based on interaction rules, timing requirements, and synergies
- **SupplementDatabaseService** - JSON database (199 supplements) with search. Fields: names, timing, requiresFat, avoidWith, pairsWith, spacing, goalRelevance, keywords, benefits
- **NotificationService** - UNUserNotificationCenter wrapper with action buttons (Mark as Taken, Snooze)
- **StreakService** - Streak calculation from IntakeLog history

### SwiftData Schema
- **User** - Root entity with meal times, goals, notification settings, relationships to supplements/scheduleSlots/intakeLogs
- **Supplement** - User's active supplements (name, dosage, form, category)
- **ScheduleSlot** - Daily schedule rules with MealContext enum and ScheduleFrequency (daily/specificDays/everyNDays/weekly)
- **IntakeLog** - Daily tracking with taken/skipped supplement arrays

### Widget Integration
Uses SharedContainer (App Groups: group.com.suplo.shared) to share data. Call `WidgetCenter.reloadAllTimelines()` after supplement state changes.

## Scheduling Algorithm Rules

Located in SchedulingService.swift:
- Fat-soluble vitamins: schedule with food
- Empty stomach items (iron, amino acids): 30-60 min before meals
- Evening supplements (magnesium, glycine): bedtime slot
- Mineral conflicts: space 2+ hours (iron/calcium, zinc/copper)
- Synergies: pair vitamin D with K2, iron with vitamin C

## Conventions

- Views: `<Feature>View.swift`, Sheets: `<Feature>Sheet.swift`
- ViewModels: `<Feature>ViewModel.swift` with @Observable
- Services: `<Name>Service.swift` with static `shared` singleton
- Time format: "HH:mm" strings, Date format: "YYYY-MM-DD" strings
- Use `try?` for SwiftData saves (silent failures currently)
- Call `context.save()` explicitly after mutations
- Theme colors via ThemeManager (@Observable singleton)

## Key Files

- `Pillo/App/PilloApp.swift` - App entry, SwiftData modelContainer setup
- `Pillo/Services/SchedulingService.swift` - Core scheduling logic
- `Pillo/Resources/supplement_database.json` - 199 supplement definitions with interaction rules
- `Pillo/Utilities/SharedContainer.swift` - Widget data sharing
- `PRD_Pillo.md` - Full product requirements document with design system and interaction rules
