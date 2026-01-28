import Foundation
import SwiftData

enum SupplementCategory: String, Codable, CaseIterable {
    case vitaminFatSoluble = "vitamin_fat_soluble"
    case vitaminWaterSoluble = "vitamin_water_soluble"
    case mineral = "mineral"
    case omega = "omega"
    case probiotic = "probiotic"
    case herbal = "herbal"
    case aminoAcid = "amino_acid"
    case other = "other"

    var displayName: String {
        switch self {
        case .vitaminFatSoluble: return "Fat-Soluble Vitamin"
        case .vitaminWaterSoluble: return "Water-Soluble Vitamin"
        case .mineral: return "Mineral"
        case .omega: return "Omega/Fish Oil"
        case .probiotic: return "Probiotic"
        case .herbal: return "Herbal/Adaptogen"
        case .aminoAcid: return "Amino Acid"
        case .other: return "Other"
        }
    }
}

@Model
final class Supplement {
    var id: UUID
    var name: String
    var category: SupplementCategory
    var dosage: Double?
    var dosageUnit: String?
    var barcode: String?
    var isActive: Bool = true
    var isArchived: Bool = false  // When true, supplement is hidden but preserved for historical records
    var archivedAt: Date?         // When the supplement was archived
    var createdAt: Date
    var referenceId: String?
    var customTime: String?  // HH:mm format - user-specified time for manual entries
    var customFrequencyData: Data?  // Encoded ScheduleFrequency for SwiftData compatibility

    var user: User?

    // MARK: - Computed Property for Frequency

    var customFrequency: ScheduleFrequency? {
        get {
            guard let data = customFrequencyData else { return nil }
            return try? JSONDecoder().decode(ScheduleFrequency.self, from: data)
        }
        set {
            customFrequencyData = newValue.flatMap { try? JSONEncoder().encode($0) }
        }
    }

    init(
        id: UUID = UUID(),
        name: String,
        category: SupplementCategory,
        dosage: Double? = nil,
        dosageUnit: String? = nil,
        barcode: String? = nil,
        isActive: Bool = true,
        isArchived: Bool = false,
        archivedAt: Date? = nil,
        createdAt: Date = Date(),
        referenceId: String? = nil,
        customTime: String? = nil,
        customFrequency: ScheduleFrequency? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.dosage = dosage
        self.dosageUnit = dosageUnit
        self.barcode = barcode
        self.isActive = isActive
        self.isArchived = isArchived
        self.archivedAt = archivedAt
        self.createdAt = createdAt
        self.referenceId = referenceId
        self.customTime = customTime
        self.customFrequencyData = customFrequency.flatMap { try? JSONEncoder().encode($0) }
    }

    var displayDosage: String {
        guard let dosage = dosage, let unit = dosageUnit else { return "" }
        if dosage == floor(dosage) {
            return "\(Int(dosage)) \(unit)"
        }
        return "\(dosage) \(unit)"
    }
}
