//
//  CameraCapture.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI
import AVFoundation
import Photos
import VisionKit

// MARK: - Camera Capture View
struct CameraCaptureView: UIViewControllerRepresentable {
    
    @Binding var isPresented: Bool
    let onImageCaptured: (Data) -> Void
    let onError: (Error) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraDevice = .rear
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCaptureView
        
        init(_ parent: CameraCaptureView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage,
               let imageData = image.jpegData(compressionQuality: 0.9) {
                parent.onImageCaptured(imageData)
            }
            
            parent.isPresented = false
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didCancel: Bool) {
            parent.isPresented = false
        }
    }
}

// MARK: - Photo Library Picker
struct PhotoLibraryPicker: UIViewControllerRepresentable {
    
    @Binding var isPresented: Bool
    let onImageSelected: (Data) -> Void
    let onError: (Error) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotoLibraryPicker
        
        init(_ parent: PhotoLibraryPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage,
               let imageData = image.jpegData(compressionQuality: 0.9) {
                parent.onImageSelected(imageData)
            }
            
            parent.isPresented = false
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didCancel: Bool) {
            parent.isPresented = false
        }
    }
}

// MARK: - Document Scanner
@available(iOS 13.0, *)
struct DocumentScannerView: UIViewControllerRepresentable {
    
    @Binding var isPresented: Bool
    let onDocumentScanned: ([Data]) -> Void
    let onError: (Error) -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView
        
        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var imageDataArray: [Data] = []
            
            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                if let imageData = image.jpegData(compressionQuality: 0.9) {
                    imageDataArray.append(imageData)
                }
            }
            
            parent.onDocumentScanned(imageDataArray)
            parent.isPresented = false
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.onError(error)
            parent.isPresented = false
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.isPresented = false
        }
    }
}

// MARK: - Clipboard Monitor
class ClipboardMonitor: ObservableObject {
    
    @Published var hasImageContent = false
    @Published var hasTextContent = false
    @Published var hasURLContent = false
    
    private var lastChangeCount: Int = 0
    private var timer: Timer?
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        lastChangeCount = UIPasteboard.general.changeCount
        updateContentStatus()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.checkForChanges()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    func getClipboardContent() -> SharedContent? {
        let pasteboard = UIPasteboard.general
        
        // Check for image
        if pasteboard.hasImages, let image = pasteboard.image,
           let imageData = image.jpegData(compressionQuality: 0.9) {
            return SharedContent(
                type: .image,
                data: imageData,
                text: nil,
                url: nil,
                sourceApp: .clipboard,
                metadata: ["source": "clipboard", "type": "image"]
            )
        }
        
        // Check for URL
        if pasteboard.hasURLs, let url = pasteboard.url {
            return SharedContent(
                type: .web,
                data: nil,
                text: pasteboard.string,
                url: url,
                sourceApp: .clipboard,
                metadata: ["source": "clipboard", "type": "url"]
            )
        }
        
        // Check for text
        if pasteboard.hasStrings, let string = pasteboard.string {
            return SharedContent(
                type: .text,
                data: nil,
                text: string,
                url: nil,
                sourceApp: .clipboard,
                metadata: ["source": "clipboard", "type": "text"]
            )
        }
        
        return nil
    }
    
    private func checkForChanges() {
        let currentChangeCount = UIPasteboard.general.changeCount
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount
            updateContentStatus()
        }
    }
    
    private func updateContentStatus() {
        let pasteboard = UIPasteboard.general
        
        hasImageContent = pasteboard.hasImages
        hasTextContent = pasteboard.hasStrings
        hasURLContent = pasteboard.hasURLs
    }
}

// MARK: - Screen Capture Detector
class ScreenCaptureDetector: ObservableObject {
    
    @Published var recentScreenshot: UIImage?
    @Published var hasRecentScreenshot = false
    
    private var lastScreenshotDate: Date?
    
    init() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.handleScreenshot()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func getLatestScreenshot() async -> Data? {
        // Request photo library access
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized else { return nil }
        
        // Fetch the most recent screenshot
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1
        fetchOptions.predicate = NSPredicate(format: "mediaSubtype == %d", PHAssetMediaSubtype.photoScreenshot.rawValue)
        
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        guard let asset = assets.firstObject else { return nil }
        
        // Check if this screenshot is recent (within last 10 seconds)
        guard let creationDate = asset.creationDate,
              Date().timeIntervalSince(creationDate) < 10 else {
            return nil
        }
        
        // Request the image data
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                continuation.resume(returning: data)
            }
        }
    }
    
    private func handleScreenshot() {
        lastScreenshotDate = Date()
        hasRecentScreenshot = true
        
        // Reset the flag after a few seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.hasRecentScreenshot = false
        }
    }
}

