import Foundation

struct SupplementReference: Codable, Identifiable, Hashable {
    let id: String
    let names: [String]
    let category: String
    let defaultDosageMin: Double
    let defaultDosageMax: Double
    let defaultDosageUnit: String
    let timing: String
    let requiresFat: Bool
    let absorptionNotes: String
    let avoidWith: [String]
    let pairsWith: [String]
    let spacingHours: Int
    let goalRelevance: [String]

    // Enhanced metadata fields
    let keywords: [String]
    let benefits: String
    let demographics: [String]
    let deficiencySigns: [String]

    // Provide defaults for backward compatibility with existing JSON
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        names = try container.decode([String].self, forKey: .names)
        category = try container.decode(String.self, forKey: .category)
        defaultDosageMin = try container.decode(Double.self, forKey: .defaultDosageMin)
        defaultDosageMax = try container.decode(Double.self, forKey: .defaultDosageMax)
        defaultDosageUnit = try container.decode(String.self, forKey: .defaultDosageUnit)
        timing = try container.decode(String.self, forKey: .timing)
        requiresFat = try container.decode(Bool.self, forKey: .requiresFat)
        absorptionNotes = try container.decode(String.self, forKey: .absorptionNotes)
        avoidWith = try container.decode([String].self, forKey: .avoidWith)
        pairsWith = try container.decode([String].self, forKey: .pairsWith)
        spacingHours = try container.decode(Int.self, forKey: .spacingHours)
        goalRelevance = try container.decode([String].self, forKey: .goalRelevance)

        // New fields with defaults
        keywords = try container.decodeIfPresent([String].self, forKey: .keywords) ?? []
        benefits = try container.decodeIfPresent(String.self, forKey: .benefits) ?? ""
        demographics = try container.decodeIfPresent([String].self, forKey: .demographics) ?? []
        deficiencySigns = try container.decodeIfPresent([String].self, forKey: .deficiencySigns) ?? []
    }

    var primaryName: String {
        names.first ?? id
    }

    var supplementCategory: SupplementCategory {
        SupplementCategory(rawValue: category) ?? .other
    }

    var displayDosageRange: String {
        let minStr = defaultDosageMin == floor(defaultDosageMin) ? String(Int(defaultDosageMin)) : String(defaultDosageMin)
        let maxStr = defaultDosageMax == floor(defaultDosageMax) ? String(Int(defaultDosageMax)) : String(defaultDosageMax)
        return "\(minStr)-\(maxStr) \(defaultDosageUnit)"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SupplementReference, rhs: SupplementReference) -> Bool {
        lhs.id == rhs.id
    }
}

struct SupplementInteraction: Codable {
    let supplementA: String
    let supplementB: String
    let spacingHours: Int
    let severity: String
    let description: String
}

struct SupplementSynergy: Codable {
    let supplementA: String
    let supplementB: String
    let effect: String
}

struct SupplementDatabase: Codable {
    let supplements: [SupplementReference]
    let interactions: [SupplementInteraction]
    let synergies: [SupplementSynergy]
}
