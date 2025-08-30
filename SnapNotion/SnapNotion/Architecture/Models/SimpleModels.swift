//
//  SimpleModels.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import Foundation
import CoreLocation
import SwiftUI

// Import the ProcessingStatus from ContentProcessingPipeline
// ProcessingStatus is defined in ContentProcessingPipeline.swift

// MARK: - Basic Content Models for MVP
struct ContentItem: Identifiable {
    let id: UUID
    let title: String
    let preview: String
    let source: String
    let sourceApp: AppSource
    let type: ContentType
    let isFavorite: Bool
    let timestamp: Date
    let attachments: [AttachmentPreview]
    let processingStatus: ProcessingStatus
    
    init(id: UUID = UUID(), title: String, preview: String, source: String, sourceApp: AppSource = .other, type: ContentType, isFavorite: Bool = false, timestamp: Date = Date(), attachments: [AttachmentPreview] = [], processingStatus: ProcessingStatus = .completed) {
        self.id = id
        self.title = title
        self.preview = preview
        self.source = source
        self.sourceApp = sourceApp
        self.type = type
        self.isFavorite = isFavorite
        self.timestamp = timestamp
        self.attachments = attachments
        self.processingStatus = processingStatus
    }
}

// ProcessingStatus is defined in ContentProcessingPipeline.swift - removed duplicate definition
// UI extensions for ProcessingStatus
extension ProcessingStatus {
    var icon: String {
        switch self {
        case .pending: return "clock"
        case .processing: return "arrow.2.circlepath"
        case .completed: return "checkmark.circle"
        case .failed: return "xmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .processing: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
}

enum ContentType: String, CaseIterable, Codable {
    case text = "text"
    case image = "image"
    case pdf = "pdf"
    case web = "web"
    case mixed = "mixed"
    
    var displayName: String {
        switch self {
        case .text: return "Text"
        case .image: return "Image"
        case .pdf: return "PDF"
        case .web: return "Web"
        case .mixed: return "Mixed"
        }
    }
    
    var color: Color {
        switch self {
        case .text: return .blue
        case .image: return .green
        case .pdf: return .red
        case .web: return .orange
        case .mixed: return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .text: return "text.alignleft"
        case .image: return "photo"
        case .pdf: return "doc.fill"
        case .web: return "globe"
        case .mixed: return "doc.on.doc"
        }
    }
}

enum ContentFilter: Identifiable, Equatable, Hashable {
    case all
    case favorites
    case images
    case documents
    case web
    case bySource(AppSource)
    
    static var allCases: [ContentFilter] = [.all, .favorites, .images, .documents, .web]
    
    var id: String {
        switch self {
        case .all: return "all"
        case .favorites: return "favorites"
        case .images: return "images"
        case .documents: return "documents"
        case .web: return "web"
        case .bySource(let source): return "bySource-\(source.rawValue)"
        }
    }
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .favorites: return "Favorites"
        case .images: return "Images"
        case .documents: return "Documents"
        case .web: return "Web"
        case .bySource(let source): return source.displayName
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "doc.on.doc"
        case .favorites: return "star.fill"
        case .images: return "photo"
        case .documents: return "doc.text"
        case .web: return "globe"
        case .bySource(let source): return source.icon
        }
    }
}

enum AppSource: String, CaseIterable, Codable {
    case clipboard = "clipboard"
    case camera = "camera"
    case photos = "photos"
    case safari = "safari"
    case whatsapp = "whatsapp"
    case tiktok = "tiktok"
    case wechat = "wechat"
    case instagram = "instagram"
    case twitter = "twitter"
    case unknown = "unknown"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .clipboard: return "Clipboard"
        case .camera: return "Camera"
        case .photos: return "Photos"
        case .safari: return "Safari"
        case .whatsapp: return "WhatsApp"
        case .tiktok: return "TikTok"
        case .wechat: return "WeChat"
        case .instagram: return "Instagram"
        case .twitter: return "Twitter"
        case .unknown: return "Unknown"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .clipboard: return "doc.on.clipboard"
        case .camera: return "camera"
        case .photos: return "photo"
        case .safari: return "safari"
        case .whatsapp: return "message.circle"
        case .tiktok: return "video.circle"
        case .wechat: return "message.badge"
        case .instagram: return "camera.circle"
        case .twitter: return "bird"
        case .unknown: return "questionmark.circle"
        case .other: return "app"
        }
    }
    
    var color: Color {
        switch self {
        case .clipboard: return .orange
        case .camera: return .green
        case .photos: return .blue
        case .safari: return .cyan
        case .whatsapp: return .green
        case .tiktok: return .black
        case .wechat: return .green
        case .instagram: return .purple
        case .twitter: return .blue
        case .unknown: return .gray
        case .other: return .gray
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

struct AttachmentPreview: Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let size: Int64
    let thumbnailPath: String?
    let fullPath: String
}

// MARK: - Simple Service Protocols
protocol ContentServiceProtocol {
    func fetchContent(page: Int, pageSize: Int, filter: ContentFilter, searchQuery: String?) async throws -> [ContentItem]
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
                title: "Welcome to SnapNotion",
                preview: "Your intelligent content management system is ready to capture and organize your digital life.",
                source: "System",
                sourceApp: .other,
                type: .text,
                isFavorite: true
            ),
            ContentItem(
                title: "Getting Started", 
                preview: "Tap the + button to capture content from any app. Use the camera, import photos, or paste from clipboard.",
                source: "System",
                sourceApp: .other,
                type: .text,
                isFavorite: false,
                timestamp: Date().addingTimeInterval(-3600)
            )
        ]
    }
}