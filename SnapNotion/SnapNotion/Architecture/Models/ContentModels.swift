//
//  ContentModels.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI
import Foundation

// MARK: - Enhanced Content Item Model
struct ContentItem: Identifiable, Codable, Hashable {
    let id = UUID()
    let title: String
    let preview: String
    let source: String
    let sourceApp: AppSource
    let timestamp: Date
    let type: ContentType
    var isFavorite: Bool
    let attachments: [AttachmentPreview]
    let metadata: ContentMetadata
    let processingStatus: ProcessingStatus
    
    // MARK: - Hashable Conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ContentItem, rhs: ContentItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Content Type
enum ContentType: String, CaseIterable, Codable {
    case text = "text"
    case web = "web"
    case pdf = "pdf"
    case image = "image"
    case mixed = "mixed"
    case video = "video"
    case audio = "audio"
    
    var icon: String {
        switch self {
        case .text: return "doc.text"
        case .web: return "globe"
        case .pdf: return "doc.richtext"
        case .image: return "photo"
        case .mixed: return "doc.on.doc"
        case .video: return "video"
        case .audio: return "waveform"
        }
    }
    
    var color: Color {
        switch self {
        case .text: return .blue
        case .web: return .green
        case .pdf: return .red
        case .image: return .purple
        case .mixed: return .orange
        case .video: return .pink
        case .audio: return .cyan
        }
    }
    
    var displayName: String {
        switch self {
        case .text: return "文本"
        case .web: return "网页"
        case .pdf: return "PDF"
        case .image: return "图片"
        case .mixed: return "混合"
        case .video: return "视频"
        case .audio: return "音频"
        }
    }
}

// MARK: - App Source
enum AppSource: String, CaseIterable, Codable {
    case whatsapp = "whatsapp"
    case tiktok = "tiktok"
    case wechat = "wechat"
    case instagram = "instagram"
    case twitter = "twitter"
    case safari = "safari"
    case photos = "photos"
    case clipboard = "clipboard"
    case camera = "camera"
    case files = "files"
    case notes = "notes"
    case mail = "mail"
    case messages = "messages"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .whatsapp: return "WhatsApp"
        case .tiktok: return "TikTok"
        case .wechat: return "微信"
        case .instagram: return "Instagram"
        case .twitter: return "Twitter"
        case .safari: return "Safari"
        case .photos: return "照片"
        case .clipboard: return "剪贴板"
        case .camera: return "相机"
        case .files: return "文件"
        case .notes: return "备忘录"
        case .mail: return "邮件"
        case .messages: return "信息"
        case .unknown: return "未知"
        }
    }
    
    var icon: String {
        switch self {
        case .whatsapp: return "message.circle"
        case .tiktok: return "play.circle"
        case .wechat: return "bubble.left.and.bubble.right"
        case .instagram: return "camera.circle"
        case .twitter: return "bird"
        case .safari: return "safari"
        case .photos: return "photo.on.rectangle"
        case .clipboard: return "doc.on.clipboard"
        case .camera: return "camera"
        case .files: return "folder"
        case .notes: return "note.text"
        case .mail: return "envelope"
        case .messages: return "message"
        case .unknown: return "questionmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .whatsapp: return .green
        case .tiktok: return .black
        case .wechat: return .green
        case .instagram: return .purple
        case .twitter: return .blue
        case .safari: return .blue
        case .photos: return .yellow
        case .clipboard: return .gray
        case .camera: return .black
        case .files: return .blue
        case .notes: return .yellow
        case .mail: return .blue
        case .messages: return .green
        case .unknown: return .gray
        }
    }
}

// MARK: - Attachment Preview
struct AttachmentPreview: Identifiable, Codable, Hashable {
    let id = UUID()
    let name: String
    let type: String
    let size: Int64
    let thumbnailPath: String?
    let fullPath: String
    
    var fileExtension: String {
        URL(fileURLWithPath: name).pathExtension.uppercased()
    }
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

// MARK: - Content Metadata
struct ContentMetadata: Codable {
    let originalURL: URL?
    let imageMetadata: ImageMetadata?
    let textMetadata: TextMetadata?
    let webMetadata: WebMetadata?
    let extractedAt: Date
    let aiProcessingResults: AIProcessingResults?
    
    init(
        originalURL: URL? = nil,
        imageMetadata: ImageMetadata? = nil,
        textMetadata: TextMetadata? = nil,
        webMetadata: WebMetadata? = nil,
        extractedAt: Date = Date(),
        aiProcessingResults: AIProcessingResults? = nil
    ) {
        self.originalURL = originalURL
        self.imageMetadata = imageMetadata
        self.textMetadata = textMetadata
        self.webMetadata = webMetadata
        self.extractedAt = extractedAt
        self.aiProcessingResults = aiProcessingResults
    }
}

// MARK: - Image Metadata
struct ImageMetadata: Codable {
    let dimensions: CGSize
    let colorSpace: String
    let hasAlpha: Bool
    let dpi: Double
    let cameraMake: String?
    let cameraModel: String?
    let location: CLLocationCoordinate2D?
    let captureDate: Date?
    
    private enum CodingKeys: String, CodingKey {
        case dimensions, colorSpace, hasAlpha, dpi
        case cameraMake, cameraModel, captureDate
        case latitude, longitude
    }
    
    init(
        dimensions: CGSize,
        colorSpace: String = "sRGB",
        hasAlpha: Bool = false,
        dpi: Double = 72.0,
        cameraMake: String? = nil,
        cameraModel: String? = nil,
        location: CLLocationCoordinate2D? = nil,
        captureDate: Date? = nil
    ) {
        self.dimensions = dimensions
        self.colorSpace = colorSpace
        self.hasAlpha = hasAlpha
        self.dpi = dpi
        self.cameraMake = cameraMake
        self.cameraModel = cameraModel
        self.location = location
        self.captureDate = captureDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dimensions = try container.decode(CGSize.self, forKey: .dimensions)
        colorSpace = try container.decode(String.self, forKey: .colorSpace)
        hasAlpha = try container.decode(Bool.self, forKey: .hasAlpha)
        dpi = try container.decode(Double.self, forKey: .dpi)
        cameraMake = try container.decodeIfPresent(String.self, forKey: .cameraMake)
        cameraModel = try container.decodeIfPresent(String.self, forKey: .cameraModel)
        captureDate = try container.decodeIfPresent(Date.self, forKey: .captureDate)
        
        if let lat = try container.decodeIfPresent(Double.self, forKey: .latitude),
           let lng = try container.decodeIfPresent(Double.self, forKey: .longitude) {
            location = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        } else {
            location = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(dimensions, forKey: .dimensions)
        try container.encode(colorSpace, forKey: .colorSpace)
        try container.encode(hasAlpha, forKey: .hasAlpha)
        try container.encode(dpi, forKey: .dpi)
        try container.encodeIfPresent(cameraMake, forKey: .cameraMake)
        try container.encodeIfPresent(cameraModel, forKey: .cameraModel)
        try container.encodeIfPresent(captureDate, forKey: .captureDate)
        
        if let location = location {
            try container.encode(location.latitude, forKey: .latitude)
            try container.encode(location.longitude, forKey: .longitude)
        }
    }
}

// MARK: - Text Metadata
struct TextMetadata: Codable {
    let wordCount: Int
    let characterCount: Int
    let language: String?
    let encoding: String
    let extractedEntities: [String]
    let sentiment: TextSentiment?
    
    enum TextSentiment: String, Codable {
        case positive, negative, neutral
        
        var displayName: String {
            switch self {
            case .positive: return "积极"
            case .negative: return "消极"
            case .neutral: return "中性"
            }
        }
        
        var color: Color {
            switch self {
            case .positive: return .green
            case .negative: return .red
            case .neutral: return .gray
            }
        }
    }
}

// MARK: - Web Metadata
struct WebMetadata: Codable {
    let title: String?
    let description: String?
    let siteName: String?
    let faviconURL: URL?
    let imageURL: URL?
    let publishedDate: Date?
    let author: String?
    let tags: [String]
}

// MARK: - AI Processing Results
struct AIProcessingResults: Codable {
    let extractedText: String?
    let detectedObjects: [DetectedObject]
    let extractedEntities: [NamedEntity]
    let summary: String?
    let categories: [String]
    let confidence: Double
    let processingTime: TimeInterval
    
    struct DetectedObject: Codable {
        let label: String
        let confidence: Double
        let boundingBox: CGRect
    }
    
    struct NamedEntity: Codable {
        let text: String
        let type: EntityType
        let confidence: Double
        
        enum EntityType: String, Codable {
            case person, organization, location, date, money, phone, email, url
            
            var displayName: String {
                switch self {
                case .person: return "人物"
                case .organization: return "组织"
                case .location: return "地点"
                case .date: return "日期"
                case .money: return "金额"
                case .phone: return "电话"
                case .email: return "邮箱"
                case .url: return "链接"
                }
            }
        }
    }
}

// MARK: - Processing Status
enum ProcessingStatus: String, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .pending: return "待处理"
        case .processing: return "处理中"
        case .completed: return "已完成"
        case .failed: return "失败"
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
    
    var icon: String {
        switch self {
        case .pending: return "clock"
        case .processing: return "gear"
        case .completed: return "checkmark.circle"
        case .failed: return "xmark.circle"
        }
    }
}

// MARK: - CoreLocation Import
import CoreLocation