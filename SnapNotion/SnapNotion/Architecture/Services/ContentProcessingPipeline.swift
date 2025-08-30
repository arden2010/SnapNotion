//
//  ContentProcessingPipeline.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import Foundation
import Vision
import CoreML
import NaturalLanguage
import SwiftUI
import CoreData
import UniformTypeIdentifiers

// MARK: - Content Processing Pipeline

/// Comprehensive content processing system with OCR, AI analysis, and task generation
@MainActor
class ContentProcessingPipeline: ObservableObject {
    
    static let shared = ContentProcessingPipeline()
    
    // MARK: - Published Properties
    @Published var processingQueue: [ProcessingTask] = []
    @Published var isProcessing: Bool = false
    @Published var processingProgress: Double = 0.0
    
    // MARK: - Processing Components
    private let ocrProcessor = OCRProcessor()
    private let aiAnalyzer = AIContentAnalyzer()
    private let taskGenerator = TaskGenerator()
    private let relationshipExtractor = RelationshipExtractor()
    
    // MARK: - Background Processing
    private var backgroundQueue = DispatchQueue(label: "content.processing", qos: .userInitiated)
    private var processingTimer: Timer?
    private let maxConcurrentProcessing = 3
    private var activeProcessingTasks: Set<UUID> = []
    
    private init() {
        startBackgroundProcessing()
    }
    
    // MARK: - Public API
    
    /// Process captured content through the full pipeline
    func processContent(_ sharedContent: SharedContent) async throws -> ContentNode {
        let task = ProcessingTask(
            id: UUID(),
            content: sharedContent,
            status: .pending,
            priority: determinePriority(for: sharedContent)
        )
        
        addToQueue(task)
        
        return try await executeProcessingTask(task)
    }
    
    /// Process existing content node with updated AI capabilities
    func reprocessContent(_ contentNode: ContentNode) async throws -> ContentNode {
        let sharedContent = SharedContent(
            type: ContentType(rawValue: contentNode.contentType ?? "text") ?? .mixed,
            data: contentNode.contentData,
            text: contentNode.contentText,
            url: contentNode.sourceURL.flatMap { URL(string: $0) },
            sourceApp: AppSource(rawValue: contentNode.sourceApp ?? "other") ?? .other,
            metadata: extractMetadata(from: contentNode)
        )
        
        return try await processContent(sharedContent)
    }
    
    // MARK: - Processing Pipeline Implementation
    
    private func executeProcessingTask(_ task: ProcessingTask) async throws -> ContentNode {
        updateTaskStatus(task.id, to: .processing)
        
        do {
            var result = ProcessingResult(
                originalContent: task.content,
                extractedText: nil,
                ocrText: nil,
                aiInsights: nil,
                generatedTasks: [],
                relationships: [],
                tags: [],
                confidence: 0.0
            )
            
            // Step 1: Content Extraction
            result = try await performContentExtraction(task.content, result: result)
            updateProgress(0.2)
            
            // Step 2: OCR Processing (if needed)
            if hasImageData(task.content) {
                result = try await performOCRProcessing(task.content, result: result)
                updateProgress(0.4)
            }
            
            // Step 3: AI Analysis
            result = try await performAIAnalysis(result)
            updateProgress(0.6)
            
            // Step 4: Task Generation
            result = try await performTaskGeneration(result)
            updateProgress(0.8)
            
            // Step 5: Relationship Extraction
            result = try await performRelationshipExtraction(result)
            updateProgress(1.0)
            
            // Step 6: Create ContentNode
            let contentNode = try await createContentNode(from: result)
            
            updateTaskStatus(task.id, to: .completed)
            removeFromQueue(task.id)
            
            return contentNode
            
        } catch {
            updateTaskStatus(task.id, to: .failed)
            
            if let snapNotionError = error as? SnapNotionError {
                throw snapNotionError
            } else {
                throw SnapNotionError.contentProcessingFailed(underlying: error.localizedDescription)
            }
        }
    }
    
    // MARK: - Processing Steps
    
    private func performContentExtraction(_ content: SharedContent, result: ProcessingResult) async throws -> ProcessingResult {
        var updatedResult = result
        
        // Extract text content
        if let text = content.text {
            updatedResult.extractedText = text
        }
        
        // Process different content types
        switch content.type {
        case .web:
            if let url = content.url {
                updatedResult.extractedText = try await extractWebContent(from: url)
            }
        case .pdf:
            if let data = content.data {
                updatedResult.extractedText = try await extractDocumentContent(from: data)
            }
        default:
            break
        }
        
        return updatedResult
    }
    
    private func performOCRProcessing(_ content: SharedContent, result: ProcessingResult) async throws -> ProcessingResult {
        guard let imageData = content.data else { return result }
        
        do {
            let ocrResult = try await ocrProcessor.extractText(from: imageData)
            var updatedResult = result
            updatedResult.ocrText = ocrResult.text
            updatedResult.confidence = max(updatedResult.confidence, ocrResult.confidence)
            return updatedResult
        } catch {
            throw SnapNotionError.ocrExtractionFailed(reason: error.localizedDescription)
        }
    }
    
    private func performAIAnalysis(_ result: ProcessingResult) async throws -> ProcessingResult {
        let combinedText = [result.extractedText, result.ocrText]
            .compactMap { $0 }
            .joined(separator: "\n\n")
        
        guard !combinedText.isEmpty else { return result }
        
        do {
            let analysis = try await aiAnalyzer.analyzeContent(combinedText)
            var updatedResult = result
            updatedResult.aiInsights = analysis
            updatedResult.tags = analysis.suggestedTags
            updatedResult.confidence = max(updatedResult.confidence, analysis.confidence)
            return updatedResult
        } catch {
            // AI analysis is optional - don't fail the entire pipeline
            print("⚠️ AI analysis failed: \(error)")
            return result
        }
    }
    
    private func performTaskGeneration(_ result: ProcessingResult) async throws -> ProcessingResult {
        guard let insights = result.aiInsights else { return result }
        
        do {
            let tasks = try await taskGenerator.generateTasks(from: insights)
            var updatedResult = result
            updatedResult.generatedTasks = tasks
            return updatedResult
        } catch {
            // Task generation is optional
            print("⚠️ Task generation failed: \(error)")
            return result
        }
    }
    
    private func performRelationshipExtraction(_ result: ProcessingResult) async throws -> ProcessingResult {
        guard let insights = result.aiInsights else { return result }
        
        do {
            let relationships = try await relationshipExtractor.extractRelationships(from: insights)
            var updatedResult = result
            updatedResult.relationships = relationships
            return updatedResult
        } catch {
            // Relationship extraction is optional
            print("⚠️ Relationship extraction failed: \(error)")
            return result
        }
    }
    
    private func createContentNode(from result: ProcessingResult) async throws -> ContentNode {
        let context = PersistenceController.shared.container.viewContext
        
        let contentNode = ContentNode(context: context)
        contentNode.id = UUID()
        contentNode.title = generateTitle(from: result)
        contentNode.contentText = result.extractedText
        contentNode.contentData = result.originalContent.data
        contentNode.contentType = result.originalContent.type.rawValue
        contentNode.sourceApp = result.originalContent.sourceApp.rawValue
        contentNode.sourceURL = result.originalContent.url?.absoluteString
        contentNode.createdAt = Date()
        contentNode.modifiedAt = Date()
        contentNode.ocrText = result.ocrText
        contentNode.aiConfidence = result.confidence
        contentNode.processingStatus = "completed"
        
        // Encode AI insights as metadata
        if let insights = result.aiInsights {
            let encoder = JSONEncoder()
            contentNode.metadata = try encoder.encode(insights)
        }
        
        // Create generated tasks
        for taskData in result.generatedTasks {
            let task = GeneratedTask(context: context)
            task.id = UUID()
            task.title = taskData.title
            task.taskDescription = taskData.description
            task.priority = taskData.priority.rawValue
            task.status = "pending"
            task.createdAt = Date()
            task.aiConfidence = taskData.confidence
            task.sourceContent = contentNode
        }
        
        // Save context
        try context.save()
        
        return contentNode
    }
    
    // MARK: - Helper Methods
    
    private func hasImageData(_ content: SharedContent) -> Bool {
        return content.type == .image || content.data != nil
    }
    
    private func extractWebContent(from url: URL) async throws -> String {
        // Placeholder for web content extraction
        return "Web content from: \(url.absoluteString)"
    }
    
    private func extractDocumentContent(from data: Data) async throws -> String {
        // Placeholder for document content extraction
        return "Document content extracted"
    }
    
    private func generateTitle(from result: ProcessingResult) -> String {
        if let insights = result.aiInsights, !insights.title.isEmpty {
            return insights.title
        }
        
        if let text = result.extractedText ?? result.ocrText {
            // Extract first meaningful sentence as title
            let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            for sentence in sentences {
                let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.count > 10 && trimmed.count < 100 {
                    return trimmed
                }
            }
            
            // Fallback to first 50 characters
            return String(text.prefix(50)) + (text.count > 50 ? "..." : "")
        }
        
        return "Untitled Content"
    }
    
    private func extractMetadata(from contentNode: ContentNode) -> [String: Any] {
        guard let metadataData = contentNode.metadata else { return [:] }
        
        do {
            if let metadata = try JSONSerialization.jsonObject(with: metadataData) as? [String: Any] {
                return metadata
            }
        } catch {
            print("Failed to decode metadata: \(error)")
        }
        
        return [:]
    }
    
    private func determinePriority(for content: SharedContent) -> ProcessingPriority {
        switch content.sourceApp {
        case .camera:
            return .high // User is actively capturing
        case .clipboard:
            return .medium // User copied something
        default:
            return .normal
        }
    }
    
    // MARK: - Queue Management
    
    private func addToQueue(_ task: ProcessingTask) {
        processingQueue.append(task)
        processingQueue.sort { $0.priority.sortOrder < $1.priority.sortOrder }
    }
    
    private func removeFromQueue(_ taskId: UUID) {
        processingQueue.removeAll { $0.id == taskId }
        activeProcessingTasks.remove(taskId)
    }
    
    private func updateTaskStatus(_ taskId: UUID, to status: ProcessingStatus) {
        if let index = processingQueue.firstIndex(where: { $0.id == taskId }) {
            processingQueue[index].status = status
        }
    }
    
    private func updateProgress(_ progress: Double) {
        processingProgress = progress
    }
    
    private func startBackgroundProcessing() {
        processingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                await self.processNextTaskIfAvailable()
            }
        }
    }
    
    private func processNextTaskIfAvailable() async {
        guard activeProcessingTasks.count < maxConcurrentProcessing else { return }
        
        guard let nextTask = processingQueue.first(where: { $0.status == .pending }) else {
            isProcessing = false
            return
        }
        
        isProcessing = true
        activeProcessingTasks.insert(nextTask.id)
        
        Task {
            do {
                _ = try await executeProcessingTask(nextTask)
            } catch {
                print("Background processing failed: \(error)")
                updateTaskStatus(nextTask.id, to: .failed)
            }
            
            activeProcessingTasks.remove(nextTask.id)
        }
    }
}

// MARK: - Supporting Types

struct ProcessingTask {
    let id: UUID
    let content: SharedContent
    var status: ProcessingStatus
    let priority: ProcessingPriority
    let createdAt = Date()
}

struct ProcessingResult {
    let originalContent: SharedContent
    var extractedText: String?
    var ocrText: String?
    var aiInsights: AIInsights?
    var generatedTasks: [TaskData]
    var relationships: [RelationshipData]
    var tags: [String]
    var confidence: Double
}

enum ProcessingStatus {
    case pending
    case processing
    case completed
    case failed
}

enum ProcessingPriority {
    case low
    case normal
    case medium
    case high
    
    var sortOrder: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .normal: return 2
        case .low: return 3
        }
    }
}

// MARK: - OCR Processor

class OCRProcessor {
    func extractText(from imageData: Data) async throws -> OCRResult {
        guard let image = UIImage(data: imageData)?.cgImage else {
            throw SnapNotionError.ocrExtractionFailed(reason: "Invalid image data")
        }
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<OCRResult, Error>) in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: SnapNotionError.ocrExtractionFailed(reason: "No text found"))
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                let combinedText = recognizedStrings.joined(separator: "\n")
                
                // Calculate average confidence
                let confidence: Double
                if observations.isEmpty {
                    confidence = 0.0
                } else {
                    let confidenceSum = observations.reduce(0.0) { sum, observation in
                        return sum + Double(observation.topCandidates(1).first?.confidence ?? 0.0)
                    }
                    confidence = confidenceSum / Double(observations.count)
                }
                
                let result = OCRResult(text: combinedText, confidence: confidence)
                continuation.resume(returning: result)
            }
            
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US", "zh-Hans", "ja-JP"] // Support multiple languages
            
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

struct OCRResult {
    let text: String
    let confidence: Double
}

// MARK: - AI Content Analyzer

class AIContentAnalyzer {
    func analyzeContent(_ text: String) async throws -> AIInsights {
        // Use NaturalLanguage framework for basic analysis
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        
        let language = NLLanguageRecognizer.dominantLanguage(for: text)
        let sentiment = analyzeSentiment(text)
        let entities = extractEntities(text)
        let topics = extractTopics(text)
        let suggestedTags = generateTags(from: text, entities: entities, topics: topics)
        
        // Generate title from first meaningful sentence
        let title = generateTitle(from: text)
        
        // Calculate confidence based on text quality
        let confidence = calculateConfidence(text: text, language: language)
        
        return AIInsights(
            title: title,
            summary: generateSummary(text),
            language: language?.rawValue ?? "unknown",
            sentiment: sentiment,
            entities: entities,
            topics: topics,
            suggestedTags: suggestedTags,
            confidence: confidence
        )
    }
    
    private func analyzeSentiment(_ text: String) -> String {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        
        let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        
        if let score = sentiment?.rawValue, let scoreValue = Double(score) {
            if scoreValue > 0.1 { return "positive" }
            else if scoreValue < -0.1 { return "negative" }
        }
        
        return "neutral"
    }
    
    private func extractEntities(_ text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        var entities: [String] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, tokenRange in
            if let tag = tag, tag != .other {
                let entity = String(text[tokenRange])
                entities.append(entity)
            }
            return true
        }
        
        return Array(Set(entities)) // Remove duplicates
    }
    
    private func extractTopics(_ text: String) -> [String] {
        // Simple keyword extraction based on word frequency
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 3 && !commonWords.contains($0) }
        
        let wordCounts = Dictionary(words.map { ($0, 1) }, uniquingKeysWith: +)
        let sortedWords = wordCounts.sorted { $0.value > $1.value }
        
        return Array(sortedWords.prefix(5).map { $0.key })
    }
    
    private func generateTags(from text: String, entities: [String], topics: [String]) -> [String] {
        var tags = Set<String>()
        
        // Add entity-based tags
        tags.formUnion(entities.map { $0.lowercased() })
        
        // Add topic-based tags
        tags.formUnion(topics)
        
        // Add content-type based tags
        if text.contains("TODO") || text.contains("task") || text.contains("action") {
            tags.insert("task")
        }
        if text.contains("meeting") || text.contains("call") {
            tags.insert("meeting")
        }
        if text.contains("idea") || text.contains("brainstorm") {
            tags.insert("idea")
        }
        
        return Array(tags.prefix(10))
    }
    
    private func generateTitle(from text: String) -> String {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        
        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 10 && trimmed.count < 80 {
                return trimmed
            }
        }
        
        // Fallback to first 50 characters
        let firstLine = text.components(separatedBy: .newlines).first ?? ""
        return String(firstLine.prefix(50)) + (firstLine.count > 50 ? "..." : "")
    }
    
    private func generateSummary(_ text: String) -> String {
        // Simple extractive summarization - take first and most important sentences
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 20 }
        
        if sentences.isEmpty {
            return String(text.prefix(200))
        }
        
        // Take up to 3 sentences for summary
        let summaryLength = min(3, sentences.count)
        return sentences.prefix(summaryLength).joined(separator: ". ") + "."
    }
    
    private func calculateConfidence(text: String, language: NLLanguage?) -> Double {
        var confidence = 0.5 // Base confidence
        
        // Increase confidence for longer texts
        if text.count > 100 { confidence += 0.2 }
        if text.count > 500 { confidence += 0.1 }
        
        // Increase confidence for detected language
        if language != nil { confidence += 0.2 }
        
        return min(confidence, 1.0)
    }
    
    private let commonWords = Set([
        "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by", "is", "are", "was", "were", "been", "be", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should", "may", "might", "can", "this", "that", "these", "those", "i", "you", "he", "she", "it", "we", "they", "me", "him", "her", "us", "them"
    ])
}

struct AIInsights: Codable {
    let title: String
    let summary: String
    let language: String
    let sentiment: String
    let entities: [String]
    let topics: [String]
    let suggestedTags: [String]
    let confidence: Double
}

// MARK: - Task Generator

class TaskGenerator {
    func generateTasks(from insights: AIInsights) async throws -> [TaskData] {
        var tasks: [TaskData] = []
        
        // Look for explicit task indicators
        let text = insights.summary
        
        if text.lowercased().contains("todo") || text.lowercased().contains("task") {
            tasks.append(TaskData(
                title: "Follow up on: \(insights.title)",
                description: "Review and complete tasks mentioned in this content",
                priority: .medium,
                confidence: 0.8
            ))
        }
        
        if text.lowercased().contains("meeting") || text.lowercased().contains("call") {
            tasks.append(TaskData(
                title: "Prepare for meeting: \(insights.title)",
                description: "Review agenda and prepare materials for the mentioned meeting",
                priority: .high,
                confidence: 0.7
            ))
        }
        
        if text.lowercased().contains("deadline") || text.lowercased().contains("due") {
            tasks.append(TaskData(
                title: "Check deadline for: \(insights.title)",
                description: "Verify deadline and plan completion timeline",
                priority: .high,
                confidence: 0.9
            ))
        }
        
        return tasks
    }
}

struct TaskData {
    let title: String
    let description: String
    let priority: TaskPriority
    let confidence: Double
}

enum TaskPriority: String, CaseIterable {
    case low
    case medium  
    case high
    case urgent
}

// MARK: - Relationship Extractor

class RelationshipExtractor {
    func extractRelationships(from insights: AIInsights) async throws -> [RelationshipData] {
        var relationships: [RelationshipData] = []
        
        // Extract entity relationships
        for entity in insights.entities {
            relationships.append(RelationshipData(
                type: "contains_entity",
                target: entity,
                confidence: 0.8
            ))
        }
        
        // Extract topic relationships  
        for topic in insights.topics {
            relationships.append(RelationshipData(
                type: "about_topic",
                target: topic,
                confidence: 0.6
            ))
        }
        
        return relationships
    }
}

struct RelationshipData {
    let type: String
    let target: String
    let confidence: Double
}