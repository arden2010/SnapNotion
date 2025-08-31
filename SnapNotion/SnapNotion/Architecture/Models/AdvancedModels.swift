//
//  AdvancedModels.swift
//  SnapNotion
//
//  Advanced AI processing models and data structures
//  Created by A. C. on 8/31/25.
//

import Foundation
import UIKit
import CoreGraphics
import NaturalLanguage

// MARK: - Advanced Processing Results
struct AdvancedProcessingResults {
    let documentAnalysis: DocumentAnalysisResults
    let ocrResults: AdvancedOCRResults
    let semanticAnalysis: SemanticAnalysisResults
    let intelligentTasks: [IntelligentTask]
    let knowledgeConnections: [KnowledgeConnection]
    let processingTime: TimeInterval
    let confidence: Double
}

// MARK: - Document Analysis Results
struct DocumentAnalysisResults {
    let documentType: DocumentType
    let layout: DocumentLayout
    let quality: ImageQuality
    let confidence: Double
}

enum DocumentType: String, CaseIterable {
    case document = "document"
    case receipt = "receipt"
    case businessCard = "business_card"
    case whiteboard = "whiteboard"
    case presentation = "presentation"
    case form = "form"
    case table = "table"
    case screenshot = "screenshot"
    case photo = "photo"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .document: return "Document"
        case .receipt: return "Receipt"
        case .businessCard: return "Business Card"
        case .whiteboard: return "Whiteboard"
        case .presentation: return "Presentation"
        case .form: return "Form"
        case .table: return "Table"
        case .screenshot: return "Screenshot"
        case .photo: return "Photo"
        case .unknown: return "Unknown"
        }
    }
}

struct DocumentLayout {
    let hasColumns: Bool
    let hasHeaders: Bool
    let hasFooters: Bool
    let textDensity: Double
}

struct ImageQuality {
    let resolution: Resolution
    let clarity: Double
    let lighting: Double
    let orientation: Orientation
    
    enum Resolution {
        case low, medium, high, veryHigh
    }
    
    enum Orientation {
        case upright, rotated90, rotated180, rotated270, skewed
    }
}

// MARK: - Advanced OCR Results
struct AdvancedOCRResults {
    let text: String
    let textElements: [TextElement]
    let structuredContent: StructuredContent
    let documentType: DocumentType
    let confidence: Double
}

struct TextElement {
    let text: String
    let boundingBox: CGRect
    let confidence: Double
    let recognitionLevel: RecognitionLevel
    
    enum RecognitionLevel {
        case character, word, line, paragraph
    }
}

// MARK: - Structured Content
struct StructuredContent {
    let tables: [DetectedTable]
    let lists: [DetectedList]
    let keyValuePairs: [KeyValuePair]
    let contactInfo: ContactInformation?
    let dateTimeInfo: [DateTimeInfo]
}

struct DetectedTable {
    let rows: [[String]]
    let columnCount: Int
    let confidence: Double
}

struct DetectedList {
    let items: [String]
    let type: ListType
    let confidence: Double
    
    enum ListType {
        case bulleted, numbered, checkbox
    }
}

struct KeyValuePair {
    let key: String
    let value: String
    let confidence: Double
}

struct ContactInformation {
    let emails: [String]
    let phoneNumbers: [String]
    let confidence: Double
}

struct DateTimeInfo {
    let originalText: String
    let type: DateTimeType
    let confidence: Double
    
    enum DateTimeType {
        case date, time, datetime, duration
    }
}

// MARK: - Semantic Analysis Results
struct SemanticAnalysisResults {
    let fullText: String
    let language: NLLanguage
    let entities: [DetectedEntity]
    let sentiment: SentimentAnalysis
    let topics: [Topic]
    let keyPhrases: [KeyPhrase]
    let confidence: Double
}

struct DetectedEntity {
    let id: UUID
    let text: String
    let type: EntityType
    let range: NSRange
    let confidence: Double
}

enum EntityType: String, CaseIterable {
    case person = "person"
    case organization = "organization"
    case location = "location"
    case event = "event"
    case product = "product"
    case date = "date"
    case money = "money"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .person: return "Person"
        case .organization: return "Organization"
        case .location: return "Location"
        case .event: return "Event"
        case .product: return "Product"
        case .date: return "Date"
        case .money: return "Money"
        case .other: return "Other"
        }
    }
}

struct SentimentAnalysis {
    let type: SentimentType
    let score: Double // -1.0 (negative) to 1.0 (positive)
    let confidence: Double
}

enum SentimentType: String {
    case positive = "positive"
    case negative = "negative"
    case neutral = "neutral"
}

struct Topic {
    let name: String
    let relevance: Double
    let confidence: Double
}

struct KeyPhrase {
    let text: String
    let importance: Double
    let confidence: Double
}

// MARK: - Intelligent Task Generation
struct IntelligentTask: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let predictedPriority: TaskPriority
    let confidenceScore: Double
    let suggestedDueDate: Date?
    let dependencies: [UUID]
    let contextualReasons: [String]
    let category: TaskCategory
    
    enum TaskPriority: Int, CaseIterable {
        case low = 1
        case medium = 2
        case high = 3
        case urgent = 4
        
        var displayName: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .urgent: return "Urgent"
            }
        }
        
        var color: UIColor {
            switch self {
            case .low: return UIColor.systemGray
            case .medium: return UIColor.systemBlue
            case .high: return UIColor.systemOrange
            case .urgent: return UIColor.systemRed
            }
        }
    }
    
    enum TaskCategory: String, CaseIterable {
        case task = "task"
        case communication = "communication"
        case research = "research"
        case planning = "planning"
        case organization = "organization"
        case review = "review"
        
        var displayName: String {
            switch self {
            case .task: return "Task"
            case .communication: return "Communication"
            case .research: return "Research"
            case .planning: return "Planning"
            case .organization: return "Organization"
            case .review: return "Review"
            }
        }
        
        var icon: String {
            switch self {
            case .task: return "checkmark.circle"
            case .communication: return "message"
            case .research: return "magnifyingglass"
            case .planning: return "calendar"
            case .organization: return "folder"
            case .review: return "eye"
            }
        }
    }
}

// MARK: - Knowledge Graph Connections
struct KnowledgeConnection {
    let fromEntity: UUID
    let toEntity: UUID
    let relationshipType: KnowledgeRelationshipType
    let strength: Double
    let evidence: String
}

enum KnowledgeRelationshipType: String, CaseIterable {
    case relatedTo = "related_to"
    case worksFor = "works_for"
    case locatedAt = "located_at"
    case partOf = "part_of"
    case mentions = "mentions"
    case follows = "follows"
    case contains = "contains"
    case similarTo = "similar_to"
    
    var displayName: String {
        switch self {
        case .relatedTo: return "Related To"
        case .worksFor: return "Works For"
        case .locatedAt: return "Located At"
        case .partOf: return "Part Of"
        case .mentions: return "Mentions"
        case .follows: return "Follows"
        case .contains: return "Contains"
        case .similarTo: return "Similar To"
        }
    }
}

struct EntityRelationship {
    let type: KnowledgeRelationshipType
    let strength: Double
    let evidence: String
}

// MARK: - Document Intelligence Models
struct DocumentIntelligence {
    let summary: String
    let keyInsights: [String]
    let actionableItems: [String]
    let suggestedTags: [String]
    let contentScore: ContentScore
}

struct ContentScore {
    let importance: Double // 0.0 to 1.0
    let urgency: Double // 0.0 to 1.0
    let completeness: Double // 0.0 to 1.0
    let readability: Double // 0.0 to 1.0
}

// MARK: - Advanced Content Classification
struct ContentClassification {
    let primaryCategory: ContentCategory
    let secondaryCategories: [ContentCategory]
    let confidence: Double
    let reasoning: String
}

enum ContentCategory: String, CaseIterable {
    case meeting = "meeting"
    case email = "email"
    case document = "document"
    case presentation = "presentation"
    case note = "note"
    case receipt = "receipt"
    case invoice = "invoice"
    case contract = "contract"
    case research = "research"
    case reference = "reference"
    
    var displayName: String {
        switch self {
        case .meeting: return "Meeting"
        case .email: return "Email"
        case .document: return "Document"
        case .presentation: return "Presentation"
        case .note: return "Note"
        case .receipt: return "Receipt"
        case .invoice: return "Invoice"
        case .contract: return "Contract"
        case .research: return "Research"
        case .reference: return "Reference"
        }
    }
    
    var icon: String {
        switch self {
        case .meeting: return "person.2"
        case .email: return "envelope"
        case .document: return "doc"
        case .presentation: return "play.rectangle"
        case .note: return "note.text"
        case .receipt: return "receipt"
        case .invoice: return "doc.text"
        case .contract: return "doc.badge.plus"
        case .research: return "magnifyingglass"
        case .reference: return "book"
        }
    }
}

// MARK: - Pattern Recognition Results
struct PatternRecognitionResults {
    let detectedPatterns: [ContentPattern]
    let anomalies: [ContentAnomaly]
    let trends: [ContentTrend]
    let confidence: Double
}

struct ContentPattern {
    let type: PatternType
    let description: String
    let frequency: Double
    let lastSeen: Date
    
    enum PatternType {
        case recurring, template, format, workflow
    }
}

struct ContentAnomaly {
    let description: String
    let severity: AnomalySeverity
    let recommendation: String
    
    enum AnomalySeverity {
        case low, medium, high, critical
    }
}

struct ContentTrend {
    let category: String
    let direction: TrendDirection
    let strength: Double
    let timeframe: TimeInterval
    
    enum TrendDirection {
        case increasing, decreasing, stable, fluctuating
    }
}

// MARK: - Multi-Language Support Models
struct LanguageProcessingResults {
    let detectedLanguages: [LanguageDetection]
    let primaryLanguage: NLLanguage
    let translationRequired: Bool
    let translatedText: String?
    let confidence: Double
}

struct LanguageDetection {
    let language: NLLanguage
    let confidence: Double
    let textRange: NSRange
}

// MARK: - Quality Assessment Models
struct ContentQualityAssessment {
    let overallScore: Double
    let readabilityScore: Double
    let completenessScore: Double
    let accuracyScore: Double
    let relevanceScore: Double
    let suggestions: [QualityImprovement]
}

struct QualityImprovement {
    let type: ImprovementType
    let description: String
    let priority: Double
    
    enum ImprovementType {
        case clarity, structure, content, formatting, accuracy
    }
}

// MARK: - Advanced Search Models
struct SemanticSearchResult {
    let contentId: UUID
    let relevanceScore: Double
    let semanticSimilarity: Double
    let contextMatch: Double
    let highlightRanges: [NSRange]
    let explanation: String
}

struct SearchContext {
    let userQuery: String
    let intentClassification: SearchIntent
    let entityContext: [DetectedEntity]
    let timeContext: DateInterval?
    let locationContext: String?
}

enum SearchIntent: String {
    case find = "find"
    case analyze = "analyze"
    case compare = "compare"
    case summarize = "summarize"
    case extract = "extract"
}

// MARK: - Performance Monitoring Models
struct ProcessingMetrics {
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let stageMetrics: [ProcessingStage: TimeInterval]
    let memoryUsage: MemoryUsage
    let cpuUsage: Double
}

enum ProcessingStage: String {
    case imageAnalysis = "image_analysis"
    case ocrProcessing = "ocr_processing"
    case semanticAnalysis = "semantic_analysis"
    case taskGeneration = "task_generation"
    case knowledgeExtraction = "knowledge_extraction"
}

struct MemoryUsage {
    let peakUsage: Int64
    let averageUsage: Int64
    let currentUsage: Int64
}

// MARK: - Error Recovery Models
struct ProcessingError: Error {
    let stage: ProcessingStage
    let errorType: ProcessingErrorType
    let description: String
    let recoveryStrategy: RecoveryStrategy?
    let timestamp: Date
}

enum ProcessingErrorType: String {
    case imageProcessingFailed = "image_processing_failed"
    case ocrTimeout = "ocr_timeout"
    case semanticAnalysisFailed = "semantic_analysis_failed"
    case insufficientMemory = "insufficient_memory"
    case networkError = "network_error"
    case modelLoadError = "model_load_error"
}

struct RecoveryStrategy {
    let type: RecoveryType
    let description: String
    let automaticRetry: Bool
    let maxRetries: Int
    
    enum RecoveryType {
        case retry, fallback, skip, userIntervention
    }
}

// MARK: - Batch Processing Models
struct BatchProcessingRequest {
    let id: UUID
    let contentItems: [Data]
    let processingOptions: ProcessingOptions
    let priority: BatchPriority
    let createdAt: Date
}

struct ProcessingOptions {
    let enableOCR: Bool
    let enableSemanticAnalysis: Bool
    let enableTaskGeneration: Bool
    let enableKnowledgeExtraction: Bool
    let qualityThreshold: Double
    let timeoutDuration: TimeInterval
}

enum BatchPriority: Int {
    case low = 1
    case normal = 2
    case high = 3
    case urgent = 4
}

struct BatchProcessingResult {
    let requestId: UUID
    let processedCount: Int
    let failedCount: Int
    let results: [UUID: AdvancedProcessingResults]
    let errors: [UUID: ProcessingError]
    let totalDuration: TimeInterval
}