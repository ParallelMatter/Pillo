import Foundation

enum Goal: String, CaseIterable, Codable {
    case energy
    case sleep
    case immunity
    case boneHealth = "bone_health"
    case heartHealth = "heart_health"
    case skinHairNails = "skin_hair_nails"
    case athleticPerformance = "athletic_performance"
    case stress
    case cognitive

    var displayName: String {
        switch self {
        case .energy: return "Better energy"
        case .sleep: return "Improved sleep"
        case .immunity: return "Immune support"
        case .boneHealth: return "Bone health"
        case .heartHealth: return "Heart health"
        case .skinHairNails: return "Skin/hair/nails"
        case .athleticPerformance: return "Athletic performance"
        case .stress: return "Stress management"
        case .cognitive: return "Cognitive function"
        }
    }

    var icon: String {
        switch self {
        case .energy: return "bolt.fill"
        case .sleep: return "moon.fill"
        case .immunity: return "shield.fill"
        case .boneHealth: return "figure.stand"
        case .heartHealth: return "heart.fill"
        case .skinHairNails: return "sparkles"
        case .athleticPerformance: return "figure.run"
        case .stress: return "leaf.fill"
        case .cognitive: return "brain.head.profile"
        }
    }
}
