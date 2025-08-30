//
//  ScreenCaptureDetector.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import UIKit
import Photos

@MainActor
class ScreenCaptureDetector: ObservableObject {
    @Published var hasRecentScreenshot: Bool = false
    
    func getLatestScreenshot() async -> Data? {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized else {
            print("Photo library access not authorized")
            return nil
        }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1
        fetchOptions.predicate = NSPredicate(format: "mediaSubtype = %d", PHAssetMediaSubtype.photoScreenshot.rawValue)
        
        let screenshots = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        guard let latestScreenshot = screenshots.firstObject else {
            return nil
        }
        
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false
            
            PHImageManager.default().requestImage(
                for: latestScreenshot,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                if let image = image,
                   let data = image.jpegData(compressionQuality: 0.8) {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    func checkForRecentScreenshot() {
        Task {
            let data = await getLatestScreenshot()
            hasRecentScreenshot = data != nil
        }
    }
}