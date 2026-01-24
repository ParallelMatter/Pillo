import Foundation

/// Response model for OpenFoodFacts API
struct OpenFoodFactsResponse: Codable {
    let code: String
    let status: Int
    let statusVerbose: String?
    let product: OpenFoodFactsProduct?

    enum CodingKeys: String, CodingKey {
        case code
        case status
        case statusVerbose = "status_verbose"
        case product
    }

    var isFound: Bool {
        status == 1 && product != nil
    }
}

struct OpenFoodFactsProduct: Codable {
    let productName: String?
    let productNameEn: String?
    let brands: String?
    let categories: String?
    let categoriesTags: [String]?
    let quantity: String?
    let servingSize: String?
    let nutriments: OpenFoodFactsNutriments?
    let imageUrl: String?
    let imageFrontUrl: String?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case productNameEn = "product_name_en"
        case brands
        case categories
        case categoriesTags = "categories_tags"
        case quantity
        case servingSize = "serving_size"
        case nutriments
        case imageUrl = "image_url"
        case imageFrontUrl = "image_front_url"
    }

    /// Get the best available product name
    var displayName: String {
        productName ?? productNameEn ?? brands ?? "Unknown Product"
    }

    /// Check if this appears to be a supplement/vitamin product
    var isLikelySupplement: Bool {
        let supplementCategories = [
            "supplements",
            "vitamins",
            "dietary supplements",
            "food supplements",
            "minerals",
            "probiotics",
            "en:dietary-supplements",
            "en:vitamins",
            "en:food-supplements"
        ]

        if let tags = categoriesTags {
            for tag in tags {
                if supplementCategories.contains(where: { tag.lowercased().contains($0) }) {
                    return true
                }
            }
        }

        if let categories = categories?.lowercased() {
            for category in supplementCategories {
                if categories.contains(category) {
                    return true
                }
            }
        }

        return false
    }
}

struct OpenFoodFactsNutriments: Codable {
    // Common vitamin/mineral nutriments per serving
    let vitaminA: Double?
    let vitaminAUnit: String?
    let vitaminC: Double?
    let vitaminCUnit: String?
    let vitaminD: Double?
    let vitaminDUnit: String?
    let vitaminE: Double?
    let vitaminEUnit: String?
    let vitaminK: Double?
    let vitaminKUnit: String?
    let vitaminB1: Double?
    let vitaminB2: Double?
    let vitaminB6: Double?
    let vitaminB12: Double?
    let calcium: Double?
    let calciumUnit: String?
    let iron: Double?
    let ironUnit: String?
    let magnesium: Double?
    let magnesiumUnit: String?
    let zinc: Double?
    let zincUnit: String?

    enum CodingKeys: String, CodingKey {
        case vitaminA = "vitamin-a_serving"
        case vitaminAUnit = "vitamin-a_unit"
        case vitaminC = "vitamin-c_serving"
        case vitaminCUnit = "vitamin-c_unit"
        case vitaminD = "vitamin-d_serving"
        case vitaminDUnit = "vitamin-d_unit"
        case vitaminE = "vitamin-e_serving"
        case vitaminEUnit = "vitamin-e_unit"
        case vitaminK = "vitamin-k_serving"
        case vitaminKUnit = "vitamin-k_unit"
        case vitaminB1 = "vitamin-b1_serving"
        case vitaminB2 = "vitamin-b2_serving"
        case vitaminB6 = "vitamin-b6_serving"
        case vitaminB12 = "vitamin-b12_serving"
        case calcium = "calcium_serving"
        case calciumUnit = "calcium_unit"
        case iron = "iron_serving"
        case ironUnit = "iron_unit"
        case magnesium = "magnesium_serving"
        case magnesiumUnit = "magnesium_unit"
        case zinc = "zinc_serving"
        case zincUnit = "zinc_unit"
    }
}

/// Simplified product info for use in the app
struct ScannedProductInfo {
    let barcode: String
    let name: String
    let brand: String?
    let quantity: String?
    let isLikelySupplement: Bool

    init(from response: OpenFoodFactsResponse) {
        self.barcode = response.code
        self.name = response.product?.displayName ?? "Unknown Product"
        self.brand = response.product?.brands
        self.quantity = response.product?.quantity ?? response.product?.servingSize
        self.isLikelySupplement = response.product?.isLikelySupplement ?? false
    }

    var displayTitle: String {
        if let brand = brand, !brand.isEmpty && brand != name {
            return "\(brand) \(name)"
        }
        return name
    }
}
