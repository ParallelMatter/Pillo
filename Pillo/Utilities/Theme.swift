import SwiftUI
import WidgetKit

// MARK: - Theme Mode
enum ThemeMode: String, CaseIterable {
    case light
    case dark

    var colorScheme: ColorScheme {
        switch self {
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Theme Manager
@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    private let defaults = UserDefaults(suiteName: "group.com.suplo.shared") ?? .standard
    private let themeKey = "selectedTheme"

    var themeMode: ThemeMode {
        didSet {
            defaults.set(themeMode.rawValue, forKey: themeKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private init() {
        let savedValue = defaults.string(forKey: themeKey) ?? ThemeMode.light.rawValue
        self.themeMode = ThemeMode(rawValue: savedValue) ?? .light
    }

    // MARK: - Dynamic Colors
    var background: Color {
        themeMode == .dark ? Color.black : Color.white
    }

    var surface: Color {
        themeMode == .dark ? Color(hex: "1A1A1A") : Color(hex: "F5F5F5")
    }

    var textPrimary: Color {
        themeMode == .dark ? Color.white : Color.black
    }

    var textSecondary: Color {
        themeMode == .dark ? Color(hex: "888888") : Color(hex: "666666")
    }

    var border: Color {
        themeMode == .dark ? Color(hex: "333333") : Color(hex: "E0E0E0")
    }

    var success: Color { Color(hex: "4ADE80") }
    var warning: Color { Color(hex: "FBBF24") }
    var accent: Color { Color(hex: "60A5FA") }
}

// MARK: - Theme (Static Accessors)
struct Theme {
    // MARK: - Colors (Dynamic via ThemeManager)
    static var background: Color { ThemeManager.shared.background }
    static var surface: Color { ThemeManager.shared.surface }
    static var textPrimary: Color { ThemeManager.shared.textPrimary }
    static var textSecondary: Color { ThemeManager.shared.textSecondary }
    static var border: Color { ThemeManager.shared.border }
    static var success: Color { ThemeManager.shared.success }
    static var warning: Color { ThemeManager.shared.warning }
    static var accent: Color { ThemeManager.shared.accent }

    // MARK: - Typography
    static let displayFont = Font.system(size: 36, weight: .light, design: .default)
    static let displayFontLarge = Font.system(size: 40, weight: .light, design: .default)
    static let headerFont = Font.system(size: 14, weight: .medium, design: .default)
    static let titleFont = Font.system(size: 20, weight: .medium, design: .default)
    static let bodyFont = Font.system(size: 16, weight: .regular, design: .default)
    static let captionFont = Font.system(size: 12, weight: .regular, design: .default)
    static let labelFont = Font.system(size: 14, weight: .regular, design: .default)
    static let timeFont = Font.system(size: 14, weight: .medium, design: .monospaced)

    // MARK: - Spacing
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let spacingXXL: CGFloat = 48

    // MARK: - Corner Radius
    static let cornerRadiusSM: CGFloat = 8
    static let cornerRadiusMD: CGFloat = 12
    static let cornerRadiusLG: CGFloat = 16

    // MARK: - Field Heights
    static let fieldHeight: CGFloat = 52

    // MARK: - Animation
    static let animationDuration: Double = 0.3
    static let springAnimation = Animation.spring(response: 0.4, dampingFraction: 0.8)
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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

// MARK: - View Modifiers
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .tracking(0.5)
            .textCase(.uppercase)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .foregroundColor(Theme.background)
            .padding(.horizontal, Theme.spacingLG)
            .padding(.vertical, Theme.spacingMD)
            .background(Theme.textPrimary)
            .cornerRadius(Theme.cornerRadiusSM)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .tracking(0.5)
            .textCase(.uppercase)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .foregroundColor(Theme.textPrimary)
            .padding(.horizontal, Theme.spacingLG)
            .padding(.vertical, Theme.spacingMD)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusSM)
                    .stroke(Theme.border, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.6 : 1.0)
    }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.spacingLG)
            .background(Theme.surface)
            .cornerRadius(Theme.cornerRadiusMD)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}
