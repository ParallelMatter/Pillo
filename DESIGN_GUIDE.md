# Pillo Design Guide

This document defines the design system for the Pillo app. All UI components should follow these specifications for visual consistency.

**Source of Truth:** `Pillo/Utilities/Theme.swift`

---

## Color Palette

### Dynamic Colors (Theme-Aware)

| Token | Light Mode | Dark Mode | Usage |
|-------|------------|-----------|-------|
| `background` | `#FFFFFF` | `#000000` | App background |
| `surface` | `#F5F5F5` | `#1A1A1A` | Cards, elevated surfaces |
| `textPrimary` | `#000000` | `#FFFFFF` | Headings, body text |
| `textSecondary` | `#666666` | `#888888` | Captions, labels, hints |
| `border` | `#E0E0E0` | `#333333` | Dividers, outlines |

### Static Colors (Theme-Agnostic)

| Token | Hex | Usage |
|-------|-----|-------|
| `success` | `#4ADE80` | Completion states, checkmarks |
| `warning` | `#FBBF24` | Alerts, partial states |
| `accent` | `#60A5FA` | Interactive elements, links |

---

## Spacing Scale

Uses an 8pt base grid system:

| Token | Value | Usage |
|-------|-------|-------|
| `spacingXS` | 4pt | Tight element gaps |
| `spacingSM` | 8pt | Internal component spacing |
| `spacingMD` | 16pt | Standard padding, form gaps |
| `spacingLG` | 24pt | Card padding, section spacing, **sheet padding** |
| `spacingXL` | 32pt | Button horizontal padding |
| `spacingXXL` | 48pt | Large vertical spacing |

---

## Typography

| Token | Size | Weight | Usage |
|-------|------|--------|-------|
| `displayFont` | 36pt | Light | Hero text |
| `displayFontLarge` | 40pt | Light | Large hero text |
| `titleFont` | 20pt | Medium | Section titles |
| `headerFont` | 14pt | Medium | Section labels (uppercase) |
| `bodyFont` | 16pt | Regular | Body content |
| `labelFont` | 14pt | Regular | Form labels |
| `captionFont` | 12pt | Regular | Helper text, metadata |
| `timeFont` | 14pt | Medium, Monospaced | Schedule times |

---

## Corner Radii

| Token | Value | Usage |
|-------|-------|-------|
| `cornerRadiusSM` | 8pt | Buttons, small inputs |
| `cornerRadiusMD` | 12pt | Cards, pickers |
| `cornerRadiusLG` | 16pt | Large containers |

---

## Animation

| Token | Value |
|-------|-------|
| `animationDuration` | 0.3s |
| `springAnimation` | response: 0.4, damping: 0.8 |

---

## Component Patterns

### Buttons

**Primary Button** (`PrimaryButtonStyle`)
- Background: `textPrimary`
- Text: `background`, 14pt medium, uppercase, 0.5 tracking
- Padding: `spacingXL` horizontal, `spacingMD` vertical
- Corner radius: `cornerRadiusSM`
- Pressed opacity: 0.8

**Secondary Button** (`SecondaryButtonStyle`)
- Background: Clear with 1px `border` stroke
- Text: `textPrimary`, 14pt medium, uppercase, 0.5 tracking
- Padding: `spacingXL` horizontal, `spacingMD` vertical
- Corner radius: `cornerRadiusSM`
- Pressed opacity: 0.6

### Cards

Use the `cardStyle()` modifier:
- Padding: `spacingLG` (24pt)
- Background: `surface`
- Corner radius: `cornerRadiusMD` (12pt)

```swift
VStack { /* content */ }
    .cardStyle()
```

---

## Sheet Standards

All sheets must follow this consistent structure:

### Structure
```swift
var body: some View {
    NavigationStack {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {  // or VStack for short content
                VStack(alignment: .leading, spacing: Theme.spacingLG) {
                    // Content here
                }
                .padding(Theme.spacingLG)  // 24pt all sides
            }
        }
        .navigationTitle("Title")  // or "" if using custom header
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { /* cancel/done buttons */ }
    }
}
```

### Rules
- **Top padding**: Always `Theme.spacingLG` (24pt)
- **Horizontal padding**: Always `Theme.spacingLG` (24pt)
- **Content VStack spacing**: `Theme.spacingLG` between sections
- **Background**: `Theme.background.ignoresSafeArea()`
- **Navigation bar**: Use `.inline` title display mode

### Header Pattern (for detail sheets)
```swift
VStack(alignment: .leading, spacing: Theme.spacingSM) {
    Text("TITLE")
        .font(Theme.titleFont)
        .tracking(1)
        .foregroundColor(Theme.textPrimary)

    Text("Subtitle")
        .font(Theme.bodyFont)
        .foregroundColor(Theme.textSecondary)
}

Divider()
    .background(Theme.border)
```

---

## Section Labels

For form sections, use uppercase headers:

```swift
Text("SECTION NAME")
    .font(Theme.headerFont)
    .tracking(1)
    .foregroundColor(Theme.textSecondary)
```

---

## Design Principles

1. **Stark Minimalism** - Clean layouts with generous whitespace
2. **Typography-First** - Text hierarchy drives visual structure
3. **Flat & Matte** - No gradients, shadows, or gloss effects
4. **Centered Alignment** - Key content centered when appropriate
5. **Consistent Spacing** - Use spacing tokens, never arbitrary values
