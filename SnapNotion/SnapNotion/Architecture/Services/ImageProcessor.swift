//
//  ImageProcessor.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import Foundation
import UIKit
import ImageIO
import CoreImage
import CoreLocation
import Photos

// MARK: - Image Processor Protocol
protocol ImageProcessorProtocol {
    func processImage(_ imageData: Data) async throws -> ImageProcessingResults
    func generateThumbnail(from imageData: Data, size: CGSize) async throws -> Data
    func compressImage(_ imageData: Data, quality: CGFloat) async throws -> Data
    func extractMetadata(from imageData: Data) async throws -> ImageMetadata
    func optimizeForStorage(_ imageData: Data) async throws -> Data
}

// MARK: - Image Processor Implementation
@MainActor
class ImageProcessor: ImageProcessorProtocol {
    
    static let shared = ImageProcessor()
    
    // MARK: - Properties
    private let fileManager = FileManager.default
    private let aiProcessor: AIProcessorProtocol
    
    // MARK: - Initialization
    init(aiProcessor: AIProcessorProtocol = AIProcessor.shared) {
        self.aiProcessor = aiProcessor
    }
    
    // MARK: - Public Methods
    func processImage(_ imageData: Data) async throws -> ImageProcessingResults {
        guard let image = UIImage(data: imageData) else {
            throw ImageProcessorError.invalidImageData
        }
        
        // Extract metadata
        let metadata = try await extractMetadata(from: imageData)
        
        // Process with AI
        let aiResults = try await aiProcessor.processImage(imageData)
        
        // Generate thumbnails and optimized versions
        let thumbnailData = try await generateThumbnail(from: imageData, size: CGSize(width: 150, height: 150))
        let optimizedData = try await optimizeForStorage(imageData)
        
        // Save files
        let attachments = try await saveImageFiles(
            original: optimizedData,
            thumbnail: thumbnailData,
            originalName: "image_\(UUID().uuidString)"
        )
        
        return ImageProcessingResults(
            metadata: metadata,
            extractedText: aiResults.extractedText,
            extractedTitle: generateTitle(from: aiResults),
            aiResults: aiResults,
            attachments: attachments
        )
    }
    
    func generateThumbnail(from imageData: Data, size: CGSize) async throws -> Data {
        return await Task {
            guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
                  let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
                throw ImageProcessorError.thumbnailGenerationFailed
            }
            
            // Calculate aspect-fit size
            let originalSize = CGSize(width: image.width, height: image.height)
            let thumbnailSize = calculateThumbnailSize(original: originalSize, target: size)
            
            // Create thumbnail
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: max(thumbnailSize.width, thumbnailSize.height)
            ]
            
            guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
                throw ImageProcessorError.thumbnailGenerationFailed
            }
            
            // Convert to JPEG data
            let mutableData = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(mutableData, UTType.jpeg.identifier as CFString, 1, nil) else {
                throw ImageProcessorError.thumbnailGenerationFailed
            }
            
            CGImageDestinationAddImage(destination, thumbnail, [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
            guard CGImageDestinationFinalize(destination) else {
                throw ImageProcessorError.thumbnailGenerationFailed
            }
            
            return mutableData as Data
        }.value
    }
    
    func compressImage(_ imageData: Data, quality: CGFloat) async throws -> Data {
        return await Task {
            guard let image = UIImage(data: imageData) else {
                throw ImageProcessorError.invalidImageData
            }
            
            guard let compressedData = image.jpegData(compressionQuality: quality) else {
                throw ImageProcessorError.compressionFailed
            }
            
            return compressedData
        }.value
    }
    
    func extractMetadata(from imageData: Data) async throws -> ImageMetadata {
        return await Task {
            guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
                  let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
                throw ImageProcessorError.metadataExtractionFailed
            }
            
            // Basic image properties
            let pixelWidth = properties[kCGImagePropertyPixelWidth] as? Double ?? 0
            let pixelHeight = properties[kCGImagePropertyPixelHeight] as? Double ?? 0
            let colorSpace = properties[kCGImagePropertyColorModel] as? String ?? "RGB"
            let hasAlpha = properties[kCGImagePropertyHasAlpha] as? Bool ?? false
            let dpi = properties[kCGImagePropertyDPIWidth] as? Double ?? 72.0
            
            // EXIF data
            var cameraMake: String?
            var cameraModel: String?
            var captureDate: Date?
            var location: CLLocationCoordinate2D?
            
            if let exifDict = properties[kCGImagePropertyExifDictionary] as? [CFString: Any] {
                captureDate = exifDict[kCGImagePropertyExifDateTimeOriginal] as? Date
            }
            
            if let tiffDict = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any] {
                cameraMake = tiffDict[kCGImagePropertyTIFFMake] as? String
                cameraModel = tiffDict[kCGImagePropertyTIFFModel] as? String
            }
            
            if let gpsDict = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any] {
                if let latitude = gpsDict[kCGImagePropertyGPSLatitude] as? Double,
                   let longitude = gpsDict[kCGImagePropertyGPSLongitude] as? Double,
                   let latitudeRef = gpsDict[kCGImagePropertyGPSLatitudeRef] as? String,
                   let longitudeRef = gpsDict[kCGImagePropertyGPSLongitudeRef] as? String {
                    
                    let finalLatitude = latitudeRef == "S" ? -latitude : latitude
                    let finalLongitude = longitudeRef == "W" ? -longitude : longitude
                    location = CLLocationCoordinate2D(latitude: finalLatitude, longitude: finalLongitude)
                }
            }
            
            return ImageMetadata(
                dimensions: CGSize(width: pixelWidth, height: pixelHeight),
                colorSpace: colorSpace,
                hasAlpha: hasAlpha,
                dpi: dpi,
                cameraMake: cameraMake,
                cameraModel: cameraModel,
                location: location,
                captureDate: captureDate
            )
        }.value
    }
    
    func optimizeForStorage(_ imageData: Data) async throws -> Data {
        return await Task {
            guard let image = UIImage(data: imageData) else {
                throw ImageProcessorError.invalidImageData
            }
            
            let maxDimension: CGFloat = 2048
            let originalSize = image.size
            
            // Resize if too large
            if originalSize.width > maxDimension || originalSize.height > maxDimension {
                let scale = min(maxDimension / originalSize.width, maxDimension / originalSize.height)
                let newSize = CGSize(
                    width: originalSize.width * scale,
                    height: originalSize.height * scale
                )
                
                guard let resizedImage = resizeImage(image, to: newSize) else {
                    throw ImageProcessorError.optimizationFailed
                }
                
                guard let optimizedData = resizedImage.jpegData(compressionQuality: 0.85) else {
                    throw ImageProcessorError.optimizationFailed
                }
                
                return optimizedData
            } else {
                // Just compress if size is acceptable
                return try await compressImage(imageData, quality: 0.9)
            }
        }.value
    }
    
    // MARK: - Private Methods
    private func calculateThumbnailSize(original: CGSize, target: CGSize) -> CGSize {
        let aspectRatio = original.width / original.height
        let targetAspectRatio = target.width / target.height
        
        if aspectRatio > targetAspectRatio {
            // Image is wider than target
            return CGSize(width: target.width, height: target.width / aspectRatio)
        } else {
            // Image is taller than target
            return CGSize(width: target.height * aspectRatio, height: target.height)
        }
    }
    
    private func resizeImage(_ image: UIImage, to newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    private func generateTitle(from aiResults: AIProcessingResults) -> String? {
        // Generate a title based on detected objects or extracted text
        if let extractedText = aiResults.extractedText, !extractedText.isEmpty {
            let words = extractedText.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .prefix(6)
            
            if !words.isEmpty {
                return words.joined(separator: " ")
            }
        }
        
        if !aiResults.detectedObjects.isEmpty {
            let objects = aiResults.detectedObjects
                .sorted { $0.confidence > $1.confidence }
                .prefix(3)
                .map { $0.label.capitalized }
            
            return objects.joined(separator: ", ")
        }
        
        return nil
    }
    
    private func saveImageFiles(original: Data, thumbnail: Data, originalName: String) async throws -> [AttachmentPreview] {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imagesDirectory = documentsURL.appendingPathComponent("images")
        
        // Create images directory if it doesn't exist
        try? fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        
        // Save original
        let originalURL = imagesDirectory.appendingPathComponent("\(originalName)_original.jpg")
        try original.write(to: originalURL)
        
        // Save thumbnail
        let thumbnailURL = imagesDirectory.appendingPathComponent("\(originalName)_thumb.jpg")
        try thumbnail.write(to: thumbnailURL)
        
        return [
            AttachmentPreview(
                name: "\(originalName).jpg",
                type: "JPG",
                size: Int64(original.count),
                thumbnailPath: thumbnailURL.path,
                fullPath: originalURL.path
            )
        ]
    }
}

// MARK: - Image Processor Error
enum ImageProcessorError: LocalizedError {
    case invalidImageData
    case thumbnailGenerationFailed
    case compressionFailed
    case metadataExtractionFailed
    case optimizationFailed
    case fileSavingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Invalid image data"
        case .thumbnailGenerationFailed:
            return "Failed to generate thumbnail"
        case .compressionFailed:
            return "Failed to compress image"
        case .metadataExtractionFailed:
            return "Failed to extract image metadata"
        case .optimizationFailed:
            return "Failed to optimize image"
        case .fileSavingFailed:
            return "Failed to save image files"
        }
    }
}