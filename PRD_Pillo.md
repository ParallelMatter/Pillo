# Product Requirements Document: Pillo

## Claude Code Implementation Guide

---

## 1. Product Overview

### 1.1 Vision
Pillo is an iOS app that solves the problem of vitamin absorption optimization. Most people take their vitamins in a single handful—unaware that certain combinations block absorption, while proper timing and meal pairing can dramatically improve efficacy. Pillo generates a personalized daily schedule that tells users exactly when to take each supplement for maximum benefit.

### 1.2 Core Value Proposition
**"Stop wasting money on vitamins your body can't absorb."**

The app transforms complex nutritional science into a simple, actionable daily schedule.

### 1.3 Target Users
- **Primary:** Health-conscious individuals taking 3-10 supplements who want to optimize their routine
- **Secondary:** Biohackers and health optimizers taking 10+ supplements who need serious schedule management

### 1.4 Key Differentiator
Unlike existing apps that simply remind you to take vitamins, Pillo:
1. Automatically generates an optimized schedule based on absorption science
2. Accounts for vitamin-vitamin interactions (e.g., calcium blocks iron)
3. Aligns supplements with meal timing for fat-soluble vs. water-soluble needs
4. Explains the "why" behind every recommendation

---

## 2. Design Language

### 2.1 Visual Identity: "Co-Star Inspired"

The app should feel modern, premium, and slightly mystical—like Co-Star's approach to astrology, but for personal health optimization.

#### Color Palette
```
Primary Background:    #000000 (Pure Black)
Secondary Background:  #1A1A1A (Near Black - for cards/elevated surfaces)
Primary Text:          #FFFFFF (Pure White)
Secondary Text:        #888888 (Medium Gray)
Accent:                #FFFFFF (White - used sparingly for emphasis)
Subtle Borders:        #333333 (Dark Gray)
Success/Taken:         #4ADE80 (Soft Green - only color accent)
Warning:               #FBBF24 (Amber - for interaction warnings)
```

#### Typography
```
Primary Font:          SF Pro Display (iOS system font)
                       - Alternatively: Inter or Suisse Int'l for custom feel

Hierarchy:
- Hero/Display:        Light weight, 32-40pt, letter-spacing: -0.02em
- Section Headers:     Medium weight, 18-20pt, ALL CAPS, letter-spacing: 0.1em
- Body Text:           Regular weight, 16pt, line-height: 1.5
- Captions/Labels:     Regular weight, 12-14pt, letter-spacing: 0.02em
- Time Stamps:         Mono or tabular figures, Medium weight, 14pt
```

#### Design Principles
1. **Stark Minimalism:** Maximum whitespace (blackspace). Let content breathe.
2. **Typography-First:** Text is the primary visual element. No unnecessary icons.
3. **Flat & Matte:** No gradients, no shadows, no skeuomorphism.
4. **Centered Layouts:** Primary content centered, creating a calm, focused feel.
5. **Deliberate Animation:** Subtle, purposeful transitions. No bouncy effects.
6. **Blunt Honesty:** Copy should be direct, slightly irreverent, never corporate.

#### UI Components

**Cards:**
```
- Background: #1A1A1A
- Border: 1px solid #333333 (optional, use sparingly)
- Border Radius: 12px
- Padding: 20px
- No shadows
```

**Buttons:**
```
Primary:
- Background: #FFFFFF
- Text: #000000
- Border Radius: 8px
- Padding: 16px 32px
- Font: Medium weight, 14pt, ALL CAPS, letter-spacing: 0.05em

Secondary/Ghost:
- Background: transparent
- Border: 1px solid #333333
- Text: #FFFFFF
- Same sizing as primary
```

**Dividers:**
```
- 1px solid #333333
- Or: blank space (preferred)
```

**Icons:**
- Use SF Symbols (iOS native)
- Stroke weight: Regular or Light
- Color: #888888 (secondary) or #FFFFFF (primary)
- Size: 20-24pt
- Use sparingly—typography should carry meaning

---

## 3. Feature Specifications

### 3.1 Onboarding Flow

#### Screen 1: Welcome
```
Layout: Centered, full-screen black background

Content:
[Top third - empty]

PILLO

Your vitamins are fighting each other.
Let's fix that.

[Primary Button: "Get Started"]

[Bottom safe area padding]
```

#### Screen 2: Add Your Vitamins
```
Layout: Full-screen with scrollable list

Header: "WHAT DO YOU TAKE?"
Subheader: "Add everything. Even the stuff you forget."

[Search Bar - ghost style]
Search or scan barcode

[Scrollable List Area]
- Each item: Name + dosage + [X remove]
- Add manually option at bottom

[Floating action area]
[Primary Button: "Continue" - appears after 1+ items added]
```

**Input Methods (prioritized):**
1. Search from database (comprehensive supplement database)
2. Barcode scanner (using device camera)
3. Manual entry (name, type, dosage)

**Data to capture per supplement:**
```
- Name (required)
- Type/Category (auto-detected or selected):
  - Vitamin (fat-soluble: A, D, E, K)
  - Vitamin (water-soluble: B-complex, C)
  - Mineral (calcium, magnesium, zinc, iron, etc.)
  - Omega/Fish Oil
  - Probiotic
  - Herbal/Adaptogen
  - Amino Acid
  - Other
- Dosage amount (optional but encouraged)
- Dosage unit (mg, mcg, IU, etc.)
- Form (capsule, tablet, gummy, liquid, powder)
```

#### Screen 3: Meal Times
```
Layout: Centered, three time pickers

Header: "WHEN DO YOU EAT?"
Subheader: "Roughly. We're not counting calories."

BREAKFAST
[Time Picker: default 8:00 AM]

LUNCH
[Time Picker: default 12:30 PM]

DINNER
[Time Picker: default 7:00 PM]

[Toggle] I skip breakfast sometimes

[Primary Button: "Continue"]
```

#### Screen 4: Goals (Optional)
```
Layout: Multi-select list

Header: "ANY SPECIFIC GOALS?"
Subheader: "Optional. Helps us prioritize."

[ ] Better energy
[ ] Improved sleep
[ ] Immune support
[ ] Bone health
[ ] Heart health
[ ] Skin/hair/nails
[ ] Athletic performance
[ ] Stress management
[ ] Cognitive function

[Ghost Button: "Skip for now"]
[Primary Button: "Generate My Schedule"]
```

#### Screen 5: Schedule Generation
```
Layout: Centered, animated

[Minimal loading animation - pulsing circle or text]

"Analyzing interactions..."
"Optimizing absorption..."
"Building your schedule..."

[Auto-advances to Today View when complete]
```

---

### 3.2 Today View (Main Screen)

This is the primary screen users see daily.

```
Layout: Full-screen, scrollable timeline

[Status Bar - system]

[Header Area]
TODAY
January 22

[Optional: Summary Card]
┌─────────────────────────────────────┐
│  4 of 7 completed                   │
│  ████████░░░░  57%                  │
└─────────────────────────────────────┘

[Timeline - Scrollable]

7:00 AM                          ○ UPCOMING
───────────────────────────────────────
Empty stomach

  Iron (65mg)
  Vitamin C (500mg)

  "Iron absorbs best before food.
   Vitamin C boosts absorption."

  [Mark as Taken]


8:30 AM                          ○ UPCOMING
───────────────────────────────────────
With breakfast

  Multivitamin
  Vitamin D (5000 IU)
  Fish Oil (1000mg)

  "Fat-soluble vitamins need food.
   Your breakfast provides the fat they need."

  [Mark as Taken]


2:00 PM                          ✓ TAKEN
───────────────────────────────────────
Between meals

  Calcium (500mg)

  "Calcium competes with iron.
   We scheduled it 6+ hours apart."


9:00 PM                          ○ UPCOMING
───────────────────────────────────────
With dinner

  Magnesium (400mg)
  Zinc (30mg)

  "Magnesium supports sleep.
   Zinc pairs well with evening protein."

  [Mark as Taken]


[Bottom Tab Bar]
Today | Vitamins | Goals | Learn | Settings
```

**Timeline Slot States:**
- Upcoming: Circle outline, full opacity
- Taken: Filled circle with checkmark, slightly dimmed
- Missed: Circle outline, warning color, "Missed" label
- Skipped: Circle with X, dimmed

**Interaction: Mark as Taken**
- Tap button → haptic feedback → slot animates to "Taken" state
- Or swipe right on the entire slot card

**Interaction: View Details**
- Tap on any vitamin name → expands inline or slides to detail view
- Shows: Full name, dosage, why it's scheduled here, interactions being avoided

---

### 3.3 Vitamins Tab

```
Layout: List view with category groupings

Header: MY VITAMINS

[Search Bar]

MORNING - EMPTY STOMACH
  Iron                    65mg
  Vitamin C              500mg

MORNING - WITH FOOD
  Multivitamin              -
  Vitamin D            5000 IU
  Fish Oil             1000mg

AFTERNOON
  Calcium               500mg

EVENING
  Magnesium             400mg
  Zinc                   30mg

[+ Add Vitamin]

───────────────────────────────────────

INTERACTIONS DETECTED

⚠ Iron ↔ Calcium
  "These compete for absorption.
   We've scheduled them 7 hours apart."

⚠ Zinc ↔ Copper
  "High zinc can deplete copper over time.
   Consider a copper supplement if taking
   zinc long-term."
```

**Tap on any vitamin → Detail View:**
```
VITAMIN D

Type: Fat-soluble vitamin
Your dose: 5000 IU
Scheduled: 8:30 AM with breakfast

WHY THIS TIME?
Vitamin D requires dietary fat for absorption.
Taking it with your breakfast ensures your body
can actually use it.

WHAT TO AVOID
• Don't take with calcium supplements
  (can reduce absorption)
• Avoid taking late in the day
  (may affect sleep for some people)

PAIRS WELL WITH
• Vitamin K2 (helps direct calcium properly)
• Magnesium (required for D metabolism)

[Edit] [Remove]
```

---

### 3.4 Goals Tab

```
Layout: Selected goals with recommendations

Header: YOUR GOALS

[Currently selected goals displayed as pills/tags]
Energy | Sleep | Immune Support

───────────────────────────────────────

BASED ON YOUR GOALS

For better energy, consider:
  B-Complex
  CoQ10
  Iron (if deficient)

  [+ Add to My Vitamins]

For improved sleep, you're taking:
  ✓ Magnesium (400mg at 9pm)

  Consider adding:
  L-Theanine
  Glycine

  [+ Add to My Vitamins]

───────────────────────────────────────

[Disclaimer Card]
These are general wellness suggestions,
not medical advice. Always consult your
healthcare provider before starting new
supplements.

[Edit Goals]
```

---

### 3.5 Learn Tab

Educational content to build trust and engagement.

```
Layout: Article list / cards

Header: LEARN

[Featured Article Card - larger]
WHY YOUR MULTIVITAMIN MIGHT BE
CANCELING ITSELF OUT
3 min read

[Article List]
───────────────────────────────────────
The Iron-Calcium War
Why these minerals hate each other
2 min

───────────────────────────────────────
Fat-Soluble 101
A, D, E, K: What they need to work
3 min

───────────────────────────────────────
Empty Stomach: What It Actually Means
Timing tips that actually matter
2 min

───────────────────────────────────────
The $50/Month Mistake
How bad timing wastes your supplement budget
4 min
```

---

### 3.6 Settings Tab

```
Header: SETTINGS

SCHEDULE
  Breakfast time           8:00 AM  >
  Lunch time              12:30 PM  >
  Dinner time              7:00 PM  >
  I skip breakfast         [Toggle]

NOTIFICATIONS
  Reminder notifications   [Toggle: ON]
  Reminder sound           Subtle  >
  Remind me early          5 min  >

DATA
  Export my data                   >
  Connect Apple Health             >

ABOUT
  How scheduling works             >
  Privacy policy                   >
  Terms of service                 >
  Send feedback                    >
  Rate Pillo                       >

Version 1.0.0
```

---

## 4. Scheduling Algorithm

### 4.1 Core Rules Database

The algorithm applies these evidence-based rules:

```javascript
const SUPPLEMENT_RULES = {

  // FAT-SOLUBLE VITAMINS - require dietary fat
  fatSoluble: {
    vitamins: ['Vitamin A', 'Vitamin D', 'Vitamin E', 'Vitamin K', 'CoQ10', 'Omega-3', 'Fish Oil', 'Turmeric/Curcumin'],
    rule: 'WITH_MEAL',
    preferredMeal: 'BREAKFAST_OR_LUNCH', // Some find D affects sleep
    notes: 'Requires dietary fat for absorption'
  },

  // WATER-SOLUBLE VITAMINS - flexible, but some considerations
  waterSoluble: {
    vitamins: ['Vitamin C', 'B-Complex', 'B1', 'B2', 'B3', 'B5', 'B6', 'B7', 'B9', 'B12'],
    rule: 'FLEXIBLE',
    notes: 'Can be taken any time. B vitamins may boost energy—consider morning.'
  },

  // EMPTY STOMACH PREFERRED
  emptyStomach: {
    supplements: ['Iron', 'Amino Acids', 'L-Tyrosine', 'L-Glutamine'],
    rule: 'EMPTY_STOMACH',
    timing: '30-60 min before meal OR 2+ hours after',
    notes: 'Food significantly reduces absorption'
  },

  // EVENING/BEDTIME PREFERRED
  evening: {
    supplements: ['Magnesium', 'Glycine', 'L-Theanine', 'Melatonin', 'Ashwagandha'],
    rule: 'EVENING',
    notes: 'May promote relaxation and sleep'
  },

  // PROBIOTICS - variable
  probiotics: {
    rule: 'BEFORE_MEAL_OR_BEDTIME',
    notes: 'Some evidence for bedtime; before meals also effective'
  }
};

const INTERACTIONS = {
  // COMPETING MINERALS - must be spaced 2+ hours apart
  mineralCompetition: [
    { a: 'Calcium', b: 'Iron', spacing: 2, unit: 'hours', severity: 'high' },
    { a: 'Calcium', b: 'Zinc', spacing: 2, unit: 'hours', severity: 'medium' },
    { a: 'Calcium', b: 'Magnesium', spacing: 2, unit: 'hours', severity: 'medium' },
    { a: 'Iron', b: 'Zinc', spacing: 2, unit: 'hours', severity: 'medium' },
    { a: 'Zinc', b: 'Copper', spacing: 2, unit: 'hours', severity: 'medium' },
  ],

  // CAFFEINE INTERACTIONS
  caffeine: {
    reduces: ['Iron', 'Calcium', 'B Vitamins'],
    spacing: 1,
    unit: 'hours',
    note: 'Wait 1 hour after coffee/tea'
  },

  // POSITIVE PAIRINGS - schedule together
  synergies: [
    { a: 'Iron', b: 'Vitamin C', effect: 'C enhances iron absorption' },
    { a: 'Vitamin D', b: 'Vitamin K2', effect: 'K2 directs calcium properly' },
    { a: 'Calcium', b: 'Vitamin D', effect: 'D enhances calcium absorption' },
    { a: 'Turmeric', b: 'Black Pepper/Piperine', effect: 'Piperine increases curcumin absorption 2000%' },
  ],

  // FIBER SEPARATION
  fiber: {
    separateFrom: ['All supplements', 'Medications'],
    spacing: 2,
    unit: 'hours',
    note: 'Fiber can bind to and reduce absorption of many nutrients'
  }
};
```

### 4.2 Scheduling Algorithm (Pseudocode)

```
FUNCTION generateSchedule(supplements, mealTimes):

  slots = []

  // 1. Create time slots based on meals
  slots.push({ time: mealTimes.breakfast - 60min, context: 'EMPTY_STOMACH_MORNING' })
  slots.push({ time: mealTimes.breakfast, context: 'WITH_BREAKFAST' })
  slots.push({ time: midpoint(breakfast, lunch), context: 'BETWEEN_MEALS_MORNING' })
  slots.push({ time: mealTimes.lunch, context: 'WITH_LUNCH' })
  slots.push({ time: midpoint(lunch, dinner), context: 'BETWEEN_MEALS_AFTERNOON' })
  slots.push({ time: mealTimes.dinner, context: 'WITH_DINNER' })
  slots.push({ time: mealTimes.dinner + 120min, context: 'BEDTIME' })

  // 2. Assign supplements to ideal slots based on rules
  FOR each supplement in supplements:
    idealSlot = determineIdealSlot(supplement, SUPPLEMENT_RULES)
    tentativeAssignments.push({ supplement, idealSlot })

  // 3. Check for conflicts and resolve
  FOR each assignment in tentativeAssignments:
    conflicts = findConflicts(assignment, tentativeAssignments, INTERACTIONS)
    IF conflicts exist:
      resolveByMoving(assignment, conflicts, slots)

  // 4. Consolidate slots (remove empty, merge where sensible)
  finalSchedule = consolidateSlots(slots)

  // 5. Generate explanations
  FOR each slot in finalSchedule:
    slot.explanation = generateExplanation(slot.supplements, SUPPLEMENT_RULES, INTERACTIONS)

  RETURN finalSchedule
```

### 4.3 Example Output

**User's supplements:**
- Multivitamin
- Vitamin D (5000 IU)
- Fish Oil
- Iron (65mg)
- Vitamin C (500mg)
- Calcium (500mg)
- Magnesium (400mg)
- Zinc (30mg)

**User's meal times:**
- Breakfast: 8:00 AM
- Lunch: 12:30 PM
- Dinner: 7:00 PM

**Generated Schedule:**

| Time | Context | Supplements | Reasoning |
|------|---------|-------------|-----------|
| 7:00 AM | Empty stomach | Iron + Vitamin C | Iron absorbs best on empty stomach; C boosts absorption |
| 8:00 AM | With breakfast | Multivitamin, Vitamin D, Fish Oil | Fat-soluble vitamins need dietary fat |
| 2:00 PM | Between meals | Calcium | Spaced 7 hours from iron (compete for absorption) |
| 7:00 PM | With dinner | Zinc | Protein enhances zinc absorption |
| 9:00 PM | After dinner | Magnesium | Promotes relaxation; spaced from calcium |

---

## 5. Data Model

### 5.1 Core Entities

```typescript
interface User {
  id: string;
  createdAt: Date;
  mealTimes: {
    breakfast: string; // "08:00"
    lunch: string;     // "12:30"
    dinner: string;    // "19:00"
  };
  skipBreakfast: boolean;
  goals: Goal[];
  notificationSettings: NotificationSettings;
}

interface Supplement {
  id: string;
  userId: string;
  name: string;
  category: SupplementCategory;
  dosage?: number;
  dosageUnit?: string;
  form?: SupplementForm;
  barcode?: string;
  isActive: boolean;
  createdAt: Date;
}

type SupplementCategory =
  | 'vitamin_fat_soluble'
  | 'vitamin_water_soluble'
  | 'mineral'
  | 'omega'
  | 'probiotic'
  | 'herbal'
  | 'amino_acid'
  | 'other';

type SupplementForm = 'capsule' | 'tablet' | 'gummy' | 'liquid' | 'powder';

interface ScheduleSlot {
  id: string;
  userId: string;
  time: string;           // "07:00"
  context: MealContext;
  supplements: string[];  // Supplement IDs
  explanation: string;
  createdAt: Date;
}

type MealContext =
  | 'empty_stomach'
  | 'with_breakfast'
  | 'with_lunch'
  | 'with_dinner'
  | 'between_meals'
  | 'bedtime';

interface IntakeLog {
  id: string;
  userId: string;
  scheduleSlotId: string;
  date: string;           // "2025-01-22"
  status: 'taken' | 'skipped' | 'missed';
  takenAt?: Date;
  createdAt: Date;
}

type Goal =
  | 'energy'
  | 'sleep'
  | 'immunity'
  | 'bone_health'
  | 'heart_health'
  | 'skin_hair_nails'
  | 'athletic_performance'
  | 'stress'
  | 'cognitive';

interface NotificationSettings {
  enabled: boolean;
  advanceMinutes: number; // 0, 5, 10, 15
  sound: 'subtle' | 'standard' | 'none';
}
```

### 5.2 Supplement Database

The app needs a reference database of common supplements with their properties:

```typescript
interface SupplementReference {
  id: string;
  names: string[];           // ["Vitamin D", "Vitamin D3", "Cholecalciferol"]
  category: SupplementCategory;
  defaultDosageRange: {
    min: number;
    max: number;
    unit: string;
  };
  absorptionRules: {
    timing: 'with_food' | 'empty_stomach' | 'flexible' | 'evening';
    requiresFat: boolean;
    notes: string;
  };
  interactions: {
    avoidWith: string[];     // Supplement IDs to space apart
    pairsWith: string[];     // Supplement IDs that enhance absorption
    spacing: number;         // Hours to separate
  };
  goalRelevance: Goal[];     // Which goals this supplement supports
  commonBarcodes?: string[];
}
```

---

## 6. Technical Architecture

### 6.1 Recommended Stack

```
Platform:          iOS (Swift/SwiftUI)
                   Future: React Native or Flutter for cross-platform

Local Storage:     Core Data or SwiftData (iOS 17+)
                   - User profile
                   - Supplements
                   - Schedule
                   - Intake logs

Backend (MVP):     Optional - can be fully local
                   If needed: Supabase or Firebase

Notifications:     iOS Local Notifications
                   UNUserNotificationCenter

Barcode Scanning:  AVFoundation (native iOS)
                   Or: VisionKit for text recognition

Database Source:
                   - NIH Dietary Supplement Label Database (DSLD)
                   - OpenFoodFacts (for barcodes)
                   - Manual curation for interaction rules
```

### 6.2 Project Structure (SwiftUI)

```
Pillo/
├── App/
│   ├── PilloApp.swift
│   └── AppDelegate.swift
├── Models/
│   ├── User.swift
│   ├── Supplement.swift
│   ├── ScheduleSlot.swift
│   ├── IntakeLog.swift
│   └── SupplementReference.swift
├── Views/
│   ├── Onboarding/
│   │   ├── WelcomeView.swift
│   │   ├── AddVitaminsView.swift
│   │   ├── MealTimesView.swift
│   │   ├── GoalsView.swift
│   │   └── GeneratingView.swift
│   ├── Today/
│   │   ├── TodayView.swift
│   │   ├── TimeSlotCard.swift
│   │   └── SupplementPill.swift
│   ├── Vitamins/
│   │   ├── VitaminsListView.swift
│   │   ├── VitaminDetailView.swift
│   │   └── AddVitaminSheet.swift
│   ├── Goals/
│   │   ├── GoalsView.swift
│   │   └── RecommendationCard.swift
│   ├── Learn/
│   │   ├── LearnView.swift
│   │   └── ArticleView.swift
│   └── Settings/
│       └── SettingsView.swift
├── ViewModels/
│   ├── OnboardingViewModel.swift
│   ├── TodayViewModel.swift
│   ├── VitaminsViewModel.swift
│   └── ScheduleEngine.swift
├── Services/
│   ├── SchedulingService.swift
│   ├── NotificationService.swift
│   ├── BarcodeScannerService.swift
│   └── SupplementDatabaseService.swift
├── Utilities/
│   ├── Constants.swift
│   ├── Theme.swift
│   └── Extensions/
├── Resources/
│   ├── Assets.xcassets
│   ├── supplement_database.json
│   └── articles/
└── Preview Content/
```

### 6.3 Key Implementation Notes

**Theme.swift - Design System:**
```swift
import SwiftUI

struct Theme {
    // Colors
    static let background = Color.black
    static let surface = Color(hex: "1A1A1A")
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "888888")
    static let border = Color(hex: "333333")
    static let success = Color(hex: "4ADE80")
    static let warning = Color(hex: "FBBF24")

    // Typography
    static let displayFont = Font.system(size: 36, weight: .light, design: .default)
    static let headerFont = Font.system(size: 14, weight: .medium, design: .default)
    static let bodyFont = Font.system(size: 16, weight: .regular, design: .default)
    static let captionFont = Font.system(size: 12, weight: .regular, design: .default)

    // Spacing
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32
}
```

---

## 7. MVP Scope

### 7.1 Must Have (V1.0)

- [x] Onboarding flow (add vitamins, meal times)
- [x] Manual supplement entry with category selection
- [x] Schedule generation algorithm (core rules)
- [x] Today view with timeline
- [x] Mark supplements as taken
- [x] Push notification reminders
- [x] Basic supplement database (top 50 supplements)
- [x] Interaction warnings display
- [x] Settings (meal times, notifications)

### 7.2 Should Have (V1.1)

- [x] Barcode scanning
- [x] Expanded supplement database (~200 unique supplements)
- [x] Goals selection and basic recommendations
- [x] Learn tab with 5-10 articles
- [x] Intake history/streaks
- [x] Widget for home screen

### 7.3 Nice to Have (V1.2+)

- [ ] Apple Health integration
- [ ] "Savings" calculator gamification
- [ ] Social sharing of schedule
- [ ] Refill reminders
- [ ] Blood work integration
- [ ] Personalized recommendations engine
- [ ] Android version

---

## 8. Success Metrics

### 8.1 Engagement
- Daily Active Users (DAU)
- % of scheduled doses marked as taken
- 7-day retention rate (target: 40%+)
- 30-day retention rate (target: 20%+)

### 8.2 Core Value Delivery
- Average supplements per user
- Schedule regeneration rate (should be low = good initial schedule)
- Time spent on "why" explanations (indicates engagement with education)

### 8.3 Growth
- Organic installs
- App Store rating (target: 4.5+)
- Reviews mentioning "finally understand timing" or similar

---

## 9. Open Questions for Development

1. **Supplement Database:** License NIH DSLD data or build custom? OpenFoodFacts for barcodes?

2. **Offline-First:** Should the app work entirely offline, or require account creation for cloud sync?

3. **Notifications:** How aggressive? One notification per slot, or one summary notification?

4. **Monetization (Future):** Freemium (limit # of supplements)? Subscription (premium features)? One-time purchase?

5. **Medical Disclaimer:** How prominent? Required acknowledgment during onboarding?

---

## 10. Appendix: Sample Copy

### Onboarding Blurbs

**Welcome:**
> Your vitamins are fighting each other. Let's fix that.

**Add Vitamins:**
> Add everything. Even the stuff you forget.

**Meal Times:**
> Roughly. We're not counting calories.

**Goals:**
> Optional. Helps us prioritize.

**Generating:**
> Analyzing interactions...
> Optimizing absorption...
> Building your schedule...

### Explanation Examples

**Iron + Vitamin C (Morning, Empty Stomach):**
> Iron absorbs best on an empty stomach—food can cut absorption by 50%. We paired it with Vitamin C, which can boost iron uptake. Take this at least 30 minutes before breakfast.

**Vitamin D (With Breakfast):**
> Vitamin D is fat-soluble, meaning it needs dietary fat to absorb properly. Your breakfast provides the fat it needs. Some people find D affects sleep if taken too late—morning is safest.

**Calcium (Afternoon, Between Meals):**
> Calcium and iron compete for the same absorption pathways. We've spaced them 7 hours apart so your body can use both effectively. This is why timing matters.

**Magnesium (Evening):**
> Magnesium promotes muscle relaxation and may support better sleep. Evening dosing lets it work while you rest. We've also spaced it from your calcium, as they can interfere with each other.

---

## 11. Reference Implementation Prompt

When implementing this in Claude Code, start with:

```
Build an iOS app called Pillo using SwiftUI. Follow the PRD specifications exactly.

Start with:
1. Set up the project structure as defined in section 6.2
2. Implement Theme.swift with the exact color/typography values from section 2
3. Build the data models from section 5.1
4. Create the Welcome screen matching section 3.1

Use these design principles throughout:
- Pure black background (#000000)
- Minimal, centered layouts
- SF Pro Display font family
- No gradients or shadows
- Typography-forward design
- Direct, slightly irreverent copy
```

---

*Document Version: 1.0*
*Last Updated: January 22, 2026*
