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

enum SupplementForm: String, Codable, CaseIterable {
    case capsule
    case tablet
    case gummy
    case liquid
    case powder
    case softgel

    var displayName: String {
        rawValue.capitalized
    }
}

@Model
final class Supplement {
    var id: UUID
    var name: String
    var category: SupplementCategory
    var dosage: Double?
    var dosageUnit: String?
    var form: SupplementForm?
    var barcode: String?
    var isActive: Bool = true
    var isArchived: Bool = false  // When true, supplement is hidden but preserved for historical records
    var archivedAt: Date?         // When the supplement was archived
    var createdAt: Date
    var referenceId: String?

    var user: User?

    init(
        id: UUID = UUID(),
        name: String,
        category: SupplementCategory,
        dosage: Double? = nil,
        dosageUnit: String? = nil,
        form: SupplementForm? = nil,
        barcode: String? = nil,
        isActive: Bool = true,
        isArchived: Bool = false,
        archivedAt: Date? = nil,
        createdAt: Date = Date(),
        referenceId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.dosage = dosage
        self.dosageUnit = dosageUnit
        self.form = form
        self.barcode = barcode
        self.isActive = isActive
        self.isArchived = isArchived
        self.archivedAt = archivedAt
        self.createdAt = createdAt
        self.referenceId = referenceId
    }

    var displayDosage: String {
        guard let dosage = dosage, let unit = dosageUnit else { return "" }
        if dosage == floor(dosage) {
            return "\(Int(dosage))\(unit)"
        }
        return "\(dosage)\(unit)"
    }
}
