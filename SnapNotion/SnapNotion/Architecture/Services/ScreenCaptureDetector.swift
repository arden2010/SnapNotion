//
//  ScreenCaptureDetector.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import UIKit
import Photos

// MARK: - Screen Capture Detector
@MainActor
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
            Task { @MainActor in
                self.handleScreenshot()
            }
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
    
    func checkForRecentScreenshot() {
        Task {
            let data = await getLatestScreenshot()
            hasRecentScreenshot = data != nil
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