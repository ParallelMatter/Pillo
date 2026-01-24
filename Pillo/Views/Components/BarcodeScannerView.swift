import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var scannerService = BarcodeScannerService.shared
    @State private var scannedCode: String?
    @State private var productInfo: ScannedProductInfo?
    @State private var showingNotFoundAlert = false
    @State private var showingPermissionAlert = false
    @State private var isProcessing = false
    @State private var hasScanned = false

    let onProductFound: (ScannedProductInfo) -> Void
    let onManualEntry: (String) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Camera view
                    CameraPreviewView(onBarcodeScanned: handleBarcodeScan)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                        .padding(Theme.spacingLG)
                        .overlay {
                            if isProcessing {
                                RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                                    .fill(Color.black.opacity(0.6))
                                    .padding(Theme.spacingLG)
                                    .overlay {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(1.5)
                                    }
                            }
                        }

                    // Instructions
                    VStack(spacing: Theme.spacingSM) {
                        Text("Point camera at barcode")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textPrimary)

                        Text("Position the barcode within the frame")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.bottom, Theme.spacingXL)

                    // Manual entry button
                    Button(action: {
                        dismiss()
                        onManualEntry("")
                    }) {
                        Text("Enter manually instead")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.horizontal, Theme.spacingLG)
                    .padding(.bottom, Theme.spacingLG)
                }
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }
            }
            .alert("Product Not Found", isPresented: $showingNotFoundAlert) {
                Button("Try Again") {
                    hasScanned = false
                }
                Button("Enter Manually") {
                    dismiss()
                    onManualEntry(scannedCode ?? "")
                }
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("This product wasn't found in our database. Would you like to enter it manually?")
            }
            .alert("Camera Access Required", isPresented: $showingPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Please enable camera access in Settings to scan barcodes.")
            }
            .task {
                let hasPermission = await BarcodeScannerService.checkCameraPermission()
                if !hasPermission {
                    showingPermissionAlert = true
                }
            }
        }
    }

    private func handleBarcodeScan(_ code: String) {
        guard !hasScanned && !isProcessing else { return }
        hasScanned = true
        scannedCode = code
        isProcessing = true

        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        Task {
            do {
                if let product = try await BarcodeScannerService.shared.fetchProduct(barcode: code) {
                    await MainActor.run {
                        productInfo = product
                        isProcessing = false
                        dismiss()
                        onProductFound(product)
                    }
                } else {
                    await MainActor.run {
                        isProcessing = false
                        showingNotFoundAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    showingNotFoundAlert = true
                }
            }
        }
    }
}

// MARK: - Camera Preview

struct CameraPreviewView: UIViewRepresentable {
    let onBarcodeScanned: (String) -> Void

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onBarcodeScanned: onBarcodeScanned)
    }

    class Coordinator: NSObject, CameraPreviewDelegate {
        let onBarcodeScanned: (String) -> Void

        init(onBarcodeScanned: @escaping (String) -> Void) {
            self.onBarcodeScanned = onBarcodeScanned
        }

        func didScanBarcode(_ code: String) {
            onBarcodeScanned(code)
        }
    }
}

protocol CameraPreviewDelegate: AnyObject {
    func didScanBarcode(_ code: String)
}

class CameraPreviewUIView: UIView {
    weak var delegate: CameraPreviewDelegate?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCamera()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        captureSession = session

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }

        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            return
        }

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [
                .ean8,
                .ean13,
                .upce,
                .code128,
                .code39,
                .code93,
                .itf14,
                .pdf417,
                .qr,
                .dataMatrix
            ]
        } else {
            return
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = bounds
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer

        // Add scanning guide overlay
        addScanningGuide()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    private func addScanningGuide() {
        let guideLayer = CAShapeLayer()
        let guideRect = CGRect(
            x: bounds.width * 0.1,
            y: bounds.height * 0.3,
            width: bounds.width * 0.8,
            height: bounds.height * 0.4
        )

        let path = UIBezierPath(roundedRect: guideRect, cornerRadius: 12)
        guideLayer.path = path.cgPath
        guideLayer.strokeColor = UIColor.white.withAlphaComponent(0.8).cgColor
        guideLayer.fillColor = UIColor.clear.cgColor
        guideLayer.lineWidth = 2
        layer.addSublayer(guideLayer)
    }

    func stopScanning() {
        captureSession?.stopRunning()
    }

    deinit {
        stopScanning()
    }
}

extension CameraPreviewUIView: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !hasScanned else { return }

        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let stringValue = metadataObject.stringValue {
            hasScanned = true
            delegate?.didScanBarcode(stringValue)
        }
    }
}

#Preview {
    BarcodeScannerView(
        onProductFound: { product in
            print("Found: \(product.displayTitle)")
        },
        onManualEntry: { _ in
            print("Manual entry")
        }
    )
    .preferredColorScheme(.dark)
}
