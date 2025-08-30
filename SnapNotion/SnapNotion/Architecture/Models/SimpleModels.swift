//
//  SimpleModels.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import Foundation
import CoreLocation

// MARK: - Basic Content Models for MVP
struct ContentItem {
    let id: UUID
    let title: String
    let preview: String
    let source: String
    let type: ContentType
    let isFavorite: Bool
    let timestamp: Date
}

enum ContentType: String, CaseIterable {
    case text = "text"
    case image = "image"
    case pdf = "pdf"
    case mixed = "mixed"
}

enum ContentFilter: String, CaseIterable {
    case all = "all"
    case favorites = "favorites"
    case images = "images"
    case documents = "documents"
}

enum AppSource: String, CaseIterable {
    case clipboard = "clipboard"
    case camera = "camera"
    case photos = "photos"
    case safari = "safari"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .clipboard: return "Clipboard"
        case .camera: return "Camera"
        case .photos: return "Photos"
        case .safari: return "Safari"
        case .other: return "Other"
        }
    }
}

// MARK: - Shared Content Model
struct SharedContent: Codable {
    let id: UUID
    let type: ContentType
    let data: Data?
    let text: String?
    let url: URL?
    let sourceApp: AppSource
    let metadata: [String: String]
    let timestamp: Date
    
    init(type: ContentType, data: Data? = nil, text: String? = nil, url: URL? = nil, sourceApp: AppSource, metadata: [String: Any]) {
        self.id = UUID()
        self.type = type
        self.data = data
        self.text = text
        self.url = url
        self.sourceApp = sourceApp
        self.timestamp = Date()
        
        // Convert metadata to string-only dictionary for Codable compliance
        self.metadata = metadata.compactMapValues { value in
            if let string = value as? String {
                return string
            } else {
                return String(describing: value)
            }
        }
    }
}

// MARK: - Processing Results
struct ImageProcessingResults {
    let metadata: ImageMetadata
    let extractedText: String?
    let extractedTitle: String?
    let aiResults: AIProcessingResults
    let attachments: [AttachmentPreview]
}

struct ImageMetadata {
    let dimensions: CGSize
    let colorSpace: String
    let hasAlpha: Bool
    let dpi: Double
    let cameraMake: String?
    let cameraModel: String?
    let location: CLLocationCoordinate2D?
    let captureDate: Date?
}

struct AIProcessingResults {
    let extractedText: String?
    let summary: String?
    let detectedObjects: [DetectedObject]
    let confidence: Double
    let processingTime: TimeInterval
}

struct DetectedObject {
    let label: String
    let confidence: Double
    let boundingBox: CGRect?
}

struct AttachmentPreview {
    let name: String
    let type: String
    let size: Int64
    let thumbnailPath: String?
    let fullPath: String
}

// MARK: - Simple Service Protocols
protocol ContentServiceProtocol {
    func fetchAllContent() async throws -> [ContentItem]
    func processSharedContent(_ content: SharedContent) async throws -> ContentItem
    func toggleFavorite(itemId: UUID) async throws
    func deleteContent(itemId: UUID) async throws
}

protocol AIProcessorProtocol {
    func processImage(_ imageData: Data) async throws -> AIProcessingResults
}

// MARK: - Sample Data
extension ContentItem {
    static var sampleData: [ContentItem] {
        [
            ContentItem(
                id: UUID(),
                title: "Welcome to SnapNotion",
                preview: "Your intelligent content management system is ready to capture and organize your digital life.",
                source: "System",
                type: .text,
                isFavorite: true,
                timestamp: Date()
            ),
            ContentItem(
                id: UUID(),
                title: "Getting Started",
                preview: "Tap the + button to capture content from any app. Use the camera, import photos, or paste from clipboard.",
                source: "System",
                type: .text,
                isFavorite: false,
                timestamp: Date().addingTimeInterval(-3600)
            )
        ]
    }
}