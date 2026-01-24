import Foundation
import AVFoundation

/// Service for barcode scanning and OpenFoodFacts API integration
class BarcodeScannerService: ObservableObject {
    static let shared = BarcodeScannerService()

    @Published var isLoading = false
    @Published var lastError: BarcodeScannerError?

    private let baseURL = "https://world.openfoodfacts.org/api/v2/product"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    /// Fetch product info from OpenFoodFacts API
    /// - Parameter barcode: The barcode string to look up
    /// - Returns: ScannedProductInfo if found, nil otherwise
    func fetchProduct(barcode: String) async throws -> ScannedProductInfo? {
        guard !barcode.isEmpty else {
            throw BarcodeScannerError.invalidBarcode
        }

        let urlString = "\(baseURL)/\(barcode).json"
        guard let url = URL(string: urlString) else {
            throw BarcodeScannerError.invalidURL
        }

        await MainActor.run {
            isLoading = true
            lastError = nil
        }

        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw BarcodeScannerError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 404 {
                    return nil // Product not found
                }
                throw BarcodeScannerError.httpError(statusCode: httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(OpenFoodFactsResponse.self, from: data)

            if apiResponse.isFound {
                return ScannedProductInfo(from: apiResponse)
            } else {
                return nil
            }
        } catch let error as BarcodeScannerError {
            await MainActor.run {
                lastError = error
            }
            throw error
        } catch {
            let scannerError = BarcodeScannerError.networkError(error)
            await MainActor.run {
                lastError = scannerError
            }
            throw scannerError
        }
    }

    /// Check if camera access is available
    static func checkCameraPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    /// Check current camera authorization status
    static var cameraAuthorizationStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }
}

enum BarcodeScannerError: LocalizedError {
    case invalidBarcode
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case networkError(Error)
    case cameraAccessDenied
    case cameraUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidBarcode:
            return "Invalid barcode format"
        case .invalidURL:
            return "Could not create request URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "Server error (code: \(statusCode))"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .cameraAccessDenied:
            return "Camera access denied. Please enable camera access in Settings."
        case .cameraUnavailable:
            return "Camera is not available on this device"
        }
    }
}
