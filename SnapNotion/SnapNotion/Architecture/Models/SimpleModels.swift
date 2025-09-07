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
    let processingStatus: String
    
    init(id: UUID = UUID(), title: String, preview: String, source: String, sourceApp: AppSource = .other, type: ContentType, isFavorite: Bool = false, timestamp: Date = Date(), attachments: [AttachmentPreview] = [], processingStatus: String = "completed") {
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

// MARK: - Processing Status Helpers
enum ProcessingStatusType: String, CaseIterable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    
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

// Extension for ContentItem to work with ProcessingStatus
extension ContentItem {
    var processingStatusType: ProcessingStatusType {
        return ProcessingStatusType(rawValue: processingStatus) ?? .completed
    }
}

// MARK: - ContentNodeData Extensions for UI Compatibility

extension ContentNodeData {
    // Bridge to work with existing UI components
    var processingStatusType: ProcessingStatusType {
        switch processingStatus {
        case .pending: return .pending
        case .processing: return .processing
        case .completed: return .completed
        case .failed: return .failed
        }
    }
    
    var sourceApp: AppSource {
        return AppSource(rawValue: source) ?? .other
    }
    
    var attachments: [AttachmentPreview] {
        return [] // TODO: Implement attachments when needed
    }
    
    // Convert to ContentItem for UI compatibility
    func asContentItem() -> ContentItem {
        return ContentItem(
            id: id,
            title: title,
            preview: preview,
            source: source,
            sourceApp: sourceApp,
            type: type,
            isFavorite: isFavorite,
            timestamp: timestamp,
            attachments: attachments,
            processingStatus: processingStatus.rawValue
        )
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
            // Recent captures - varied sources and types
            ContentItem(
                title: "SwiftUI Grid Layout Best Practices",
                preview: "Learn how to create responsive grid layouts using LazyVGrid and GridItem. Perfect for photo galleries and card-based interfaces.",
                source: "developer.apple.com",
                sourceApp: .safari,
                type: .web,
                isFavorite: true,
                timestamp: Date().addingTimeInterval(-900) // 15 mins ago
            ),
            ContentItem(
                title: "Meeting Notes - Q4 Planning",
                preview: "Discussed product roadmap, feature prioritization, and resource allocation. Key decisions: focus on mobile-first approach, implement dark mode, launch beta in December.",
                source: "Notes App",
                sourceApp: .clipboard,
                type: .text,
                isFavorite: false,
                timestamp: Date().addingTimeInterval(-3600) // 1 hour ago
            ),
            ContentItem(
                title: "Project Timeline Screenshot",
                preview: "Gantt chart showing development milestones and dependencies for the mobile app release.",
                source: "Camera Roll",
                sourceApp: .photos,
                type: .image,
                isFavorite: false,
                timestamp: Date().addingTimeInterval(-5400) // 1.5 hours ago
            ),
            ContentItem(
                title: "AI Product Management Guide",
                preview: "Comprehensive guide on using AI tools for product management. Covers user research, feature prioritization, and data-driven decisions.",
                source: "producthunt.com",
                sourceApp: .safari,
                type: .web,
                isFavorite: true,
                timestamp: Date().addingTimeInterval(-7200) // 2 hours ago
            ),
            ContentItem(
                title: "Code Review Comments",
                preview: "Feedback on the new authentication module: Consider using async/await for better error handling, add unit tests for edge cases.",
                source: "WhatsApp",
                sourceApp: .whatsapp,
                type: .text,
                isFavorite: false,
                timestamp: Date().addingTimeInterval(-10800) // 3 hours ago
            ),
            ContentItem(
                title: "UI Design Inspiration",
                preview: "Beautiful card-based dashboard design with subtle shadows and smooth transitions. Great reference for our new interface.",
                source: "Instagram",
                sourceApp: .instagram,
                type: .image,
                isFavorite: true,
                timestamp: Date().addingTimeInterval(-14400) // 4 hours ago
            ),
            ContentItem(
                title: "Market Research Report",
                preview: "Analysis of competitor features, pricing models, and user feedback. Key insights: users want better search, offline mode is crucial.",
                source: "Documents",
                sourceApp: .camera,
                type: .pdf,
                isFavorite: false,
                timestamp: Date().addingTimeInterval(-18000) // 5 hours ago
            ),
            ContentItem(
                title: "Team Standup Updates",
                preview: "John: Fixed the sync bug, working on push notifications. Sarah: Completed user testing, 87% satisfaction rate. Mike: API optimization complete.",
                source: "WeChat",
                sourceApp: .wechat,
                type: .text,
                isFavorite: false,
                timestamp: Date().addingTimeInterval(-21600) // 6 hours ago
            ),
            ContentItem(
                title: "App Store Screenshots",
                preview: "Collection of promotional screenshots for app store listing. Shows key features: dashboard, grid view, task management.",
                source: "Camera",
                sourceApp: .camera,
                type: .image,
                isFavorite: true,
                timestamp: Date().addingTimeInterval(-25200) // 7 hours ago
            ),
            ContentItem(
                title: "React vs SwiftUI Performance",
                preview: "Detailed comparison of React Native vs native SwiftUI performance. SwiftUI shows 40% better rendering performance in complex UIs.",
                source: "medium.com",
                sourceApp: .safari,
                type: .web,
                isFavorite: false,
                timestamp: Date().addingTimeInterval(-28800) // 8 hours ago
            ),
            // Older content for variety
            ContentItem(
                title: "Customer Feedback Summary",
                preview: "Compiled user feedback from last month: 78% love the new dashboard, 65% want better search, 23% need offline sync.",
                source: "Email",
                sourceApp: .clipboard,
                type: .text,
                isFavorite: true,
                timestamp: Date().addingTimeInterval(-86400) // 1 day ago
            ),
            ContentItem(
                title: "Architecture Diagrams",
                preview: "System architecture showing microservices, database design, and API structure. Updated with new real-time sync component.",
                source: "Camera Roll",
                sourceApp: .photos,
                type: .image,
                isFavorite: false,
                timestamp: Date().addingTimeInterval(-172800) // 2 days ago
            ),
            ContentItem(
                title: "Design System Guidelines",
                preview: "Complete design system documentation: colors, typography, spacing, components. Includes dark mode specifications.",
                source: "figma.com",
                sourceApp: .safari,
                type: .web,
                isFavorite: true,
                timestamp: Date().addingTimeInterval(-259200) // 3 days ago
            )
        ]
    }
}