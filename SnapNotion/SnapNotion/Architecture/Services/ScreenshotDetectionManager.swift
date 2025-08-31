//
//  ScreenshotDetectionManager.swift
//  SnapNotion
//
//  Created by A. C. on 8/31/25.
//

import UIKit
import Photos
import SwiftUI

@MainActor
class ScreenshotDetectionManager: ObservableObject {
    
    static let shared = ScreenshotDetectionManager()
    
    @Published var isMonitoring = false
    @Published var showProcessingBanner = false
    @Published var processingMessage = ""
    @Published var lastScreenshotImage: UIImage?
    
    private let contentProcessor = ContentCaptureProcessor.shared
    private var isProcessing = false
    
    init() {
        startScreenshotMonitoring()
    }
    
    // MARK: - Screenshot Detection Methods
    
    /// Start monitoring for iOS screenshot notifications
    func startScreenshotMonitoring() {
        isMonitoring = true
        
        // Method 1: Detect screenshot notification (iOS 14+)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenshotTaken),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
        
        print("📸 SnapNotion: Started monitoring for screenshots")
    }
    
    /// Stop monitoring screenshots
    func stopScreenshotMonitoring() {
        isMonitoring = false
        NotificationCenter.default.removeObserver(self, name: UIApplication.userDidTakeScreenshotNotification, object: nil)
        print("📸 SnapNotion: Stopped monitoring screenshots")
    }
    
    // MARK: - Screenshot Notification Handler
    
    @objc private func screenshotTaken() {
        print("📸 Screenshot detected by SnapNotion!")
        
        // Prevent multiple simultaneous processing
        guard !isProcessing else { return }
        
        Task {
            await handleScreenshotDetected()
        }
    }
    
    private func handleScreenshotDetected() async {
        isProcessing = true
        
        // Show processing banner to user
        showProcessingBanner = true
        processingMessage = "📸 Screenshot detected! Processing with AI..."
        
        // Small delay to ensure screenshot is saved to Photos
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        do {
            // Attempt to get the latest screenshot from Photos
            if let screenshotImage = await getLatestScreenshot() {
                lastScreenshotImage = screenshotImage
                processingMessage = "🧠 Analyzing screenshot content..."
                
                // Process with AI
                guard let imageData = screenshotImage.jpegData(compressionQuality: 0.8) else {
                    throw ScreenshotProcessingError.imageConversionFailed
                }
                
                let contentItem = try await contentProcessor.processImage(imageData, source: "iOS Screenshot")
                
                // Show success message
                processingMessage = "✅ Screenshot processed successfully!"
                
                // Auto-dismiss after success
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                showProcessingBanner = false
                
                // Show quick action options
                await showScreenshotActionSheet(contentItem)
                
            } else {
                processingMessage = "⚠️ Could not access screenshot. Please grant Photos access."
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                showProcessingBanner = false
            }
            
        } catch {
            processingMessage = "❌ Screenshot processing failed: \(error.localizedDescription)"
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            showProcessingBanner = false
        }
        
        isProcessing = false
    }
    
    // MARK: - Photo Library Access
    
    /// Get the most recent screenshot from Photos library
    private func getLatestScreenshot() async -> UIImage? {
        return await withCheckedContinuation { continuation in
            // Check photo library permission
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            
            guard status == .authorized || status == .limited else {
                // Request permission
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                    if newStatus == .authorized || newStatus == .limited {
                        Task {
                            let image = await self.fetchLatestScreenshot()
                            continuation.resume(returning: image)
                        }
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
                return
            }
            
            Task {
                let image = await self.fetchLatestScreenshot()
                continuation.resume(returning: image)
            }
        }
    }
    
    /// Fetch the latest screenshot from Photos
    private func fetchLatestScreenshot() async -> UIImage? {
        return await withCheckedContinuation { continuation in
            // Create fetch options for recent screenshots
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 5 // Get last 5 images to find the screenshot
            
            // Fetch recent photos
            let recentPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            
            // Look for the most recent screenshot (within last 10 seconds)
            let cutoffTime = Date().addingTimeInterval(-10) // 10 seconds ago
            
            for index in 0..<recentPhotos.count {
                let asset = recentPhotos.object(at: index)
                
                // Check if the photo was created recently (likely our screenshot)
                if let creationDate = asset.creationDate, creationDate > cutoffTime {
                    
                    // Check if it's a screenshot (iOS sets specific metadata)
                    if asset.mediaSubtypes.contains(.photoScreenshot) {
                        // This is definitely a screenshot
                        self.loadImageFromAsset(asset) { image in
                            continuation.resume(returning: image)
                        }
                        return
                    }
                }
            }
            
            // If no screenshot metadata found, get the most recent image
            if recentPhotos.count > 0 {
                let mostRecent = recentPhotos.object(at: 0)
                if let creationDate = mostRecent.creationDate, creationDate > cutoffTime {
                    self.loadImageFromAsset(mostRecent) { image in
                        continuation.resume(returning: image)
                    }
                    return
                }
            }
            
            continuation.resume(returning: nil)
        }
    }
    
    /// Load UIImage from PHAsset
    private func loadImageFromAsset(_ asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        
        let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            completion(image)
        }
    }
    
    // MARK: - User Action Sheet
    
    /// Show action options after screenshot is processed
    private func showScreenshotActionSheet(_ contentItem: ContentItem) async {
        // This would trigger a SwiftUI action sheet or banner
        // Implementation depends on your UI architecture
        print("✅ Screenshot processed: \(contentItem.title)")
        
        // Could show:
        // - "View processed content"
        // - "Generate more tasks" 
        // - "Edit content"
        // - "Share results"
    }
    
    deinit {
        Task { @MainActor in
            stopScreenshotMonitoring()
        }
    }
}

// MARK: - Screenshot Processing Errors

enum ScreenshotProcessingError: LocalizedError {
    case imageConversionFailed
    case photoLibraryAccessDenied
    case screenshotNotFound
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert screenshot to processable format"
        case .photoLibraryAccessDenied:
            return "Photo library access is required to process screenshots"
        case .screenshotNotFound:
            return "Could not find the recent screenshot in your photo library"
        }
    }
}