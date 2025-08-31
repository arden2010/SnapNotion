//
//  ContentCaptureProcessor.swift
//  SnapNotion
//
//  Created by A. C. on 8/31/25.
//

import Foundation
import UIKit
import Vision
import VisionKit

// MARK: - Content Processing Errors
enum ContentProcessingError: LocalizedError {
    case imageConversionFailed
    case ocrFailed
    case aiProcessingFailed
    case invalidImageData
    case processingTimeout
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image data"
        case .ocrFailed:
            return "Text recognition failed"
        case .aiProcessingFailed:
            return "AI processing failed"
        case .invalidImageData:
            return "Invalid image data"
        case .processingTimeout:
            return "Processing timed out"
        }
    }
}

// MARK: - Content Capture Processor
@MainActor
class ContentCaptureProcessor: ObservableObject {
    
    static let shared = ContentCaptureProcessor()
    
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    
    private let imageProcessor: ImageProcessorProtocol
    private let contentService: ContentServiceProtocol
    private let advancedAIEngine = AdvancedAIEngine.shared
    private let graphEngine = GraphEngine.shared
    
    init(
        imageProcessor: ImageProcessorProtocol? = nil,
        contentService: ContentServiceProtocol? = nil
    ) {
        self.imageProcessor = imageProcessor ?? ImageProcessor.shared
        self.contentService = contentService ?? SimpleContentService.shared
    }
    
    // MARK: - Main Processing Method
    func processImage(_ imageData: Data, source: String) async throws -> ContentItem {
        isProcessing = true
        processingProgress = 0.0
        
        do {
            // Use Advanced AI Engine for comprehensive processing
            let advancedResults = try await advancedAIEngine.processContentAdvanced(imageData, source: source)
            processingProgress = 0.9
            
            // Create content item from advanced results
            let contentItem = try await createAdvancedContentItem(
                from: advancedResults,
                imageData: imageData,
                source: source
            )
            processingProgress = 1.0
            
            // Update knowledge graph with new content
            await updateKnowledgeGraph(with: contentItem, results: advancedResults)
            
            // Save generated intelligent tasks
            await saveIntelligentTasks(advancedResults.intelligentTasks, sourceContentId: contentItem.id)
            
            isProcessing = false
            return contentItem
            
        } catch {
            isProcessing = false
            processingProgress = 0.0
            throw error
        }
    }
    
    // MARK: - OCR Processing
    private func performOCR(_ imageData: Data) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            guard let image = UIImage(data: imageData)?.cgImage else {
                continuation.resume(throwing: ContentProcessingError.invalidImageData)
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let recognizedText = request.results?.compactMap { result in
                    (result as? VNRecognizedTextObservation)?.topCandidates(1).first?.string
                }.joined(separator: "\n") ?? ""
                
                continuation.resume(returning: recognizedText)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: image)
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Text Processing
    func processText(_ text: String, source: String) async throws -> ContentItem {
        // Create content item from text
        let contentItem = ContentItem(
            title: generateTitle(from: text),
            preview: generateSummary(from: text),
            source: source,
            sourceApp: .clipboard,
            type: .text
        )
        
        // Create AI results for task generation
        let aiResults = AIProcessingResults(
            extractedText: text,
            summary: generateSummary(from: text),
            detectedObjects: [],
            confidence: 1.0,
            processingTime: 0.1
        )
        
        // TODO: Generate tasks from text
        // let tasks = try await generateTasks(from: text, aiResults: aiResults)
        // Add tasks to task manager when available
        
        return contentItem
    }
    
    // MARK: - Web URL Processing  
    func processWebURL(_ url: URL, source: String) async throws -> ContentItem {
        // For now, create a simple web link content item
        // In the future, you could fetch the webpage content and analyze it
        
        let contentItem = ContentItem(
            title: url.host ?? "Web Link",
            preview: "Web link: \(url.absoluteString)",
            source: source,
            sourceApp: .clipboard,
            type: .web
        )
        
        return contentItem
    }
    
    // MARK: - Helper Methods
    private func generateTitle(from text: String) -> String {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        if words.count <= 5 {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return words.prefix(5).joined(separator: " ") + "..."
        }
    }
    
    private func generateSummary(from text: String) -> String {
        if text.count <= 100 {
            return text
        } else {
            return String(text.prefix(100)) + "..."
        }
    }
    
    // MARK: - Advanced Content Item Creation
    private func createAdvancedContentItem(
        from results: AdvancedProcessingResults,
        imageData: Data,
        source: String
    ) async throws -> ContentItem {
        
        let title = generateAdvancedTitle(from: results)
        let preview = generateAdvancedPreview(from: results)
        let contentType = determineContentType(from: results)
        
        // Create attachments from image data
        let attachments = try await createAttachments(from: imageData)
        
        return ContentItem(
            id: UUID(),
            title: title,
            preview: preview,
            source: source,
            sourceApp: determineSourceApp(from: source),
            type: contentType,
            isFavorite: false,
            timestamp: Date(),
            attachments: attachments,
            processingStatus: "completed"
        )
    }
    
    private func generateAdvancedTitle(from results: AdvancedProcessingResults) -> String {
        // Use semantic analysis results for intelligent title generation
        if let firstTopic = results.semanticAnalysis.topics.first {
            return "Content about \(firstTopic.name)"
        }
        
        if let firstEntity = results.semanticAnalysis.entities.first {
            return "\(firstEntity.type.displayName): \(firstEntity.text)"
        }
        
        // Fallback to OCR-based title
        let text = results.ocrResults.text
        if !text.isEmpty {
            let words = text.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
            
            if words.count <= 5 {
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                return words.prefix(5).joined(separator: " ") + "..."
            }
        }
        
        // Final fallback
        return "Content from \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))"
    }
    
    private func generateAdvancedPreview(from results: AdvancedProcessingResults) -> String {
        // Use AI-generated summary if available
        let summary = results.semanticAnalysis.fullText
        if !summary.isEmpty {
            return String(summary.prefix(200)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Use structured content information
        let structuredInfo = results.ocrResults.structuredContent
        var preview = ""
        
        if !structuredInfo.tables.isEmpty {
            preview += "Contains \(structuredInfo.tables.count) table(s). "
        }
        
        if !structuredInfo.lists.isEmpty {
            preview += "Contains \(structuredInfo.lists.count) list(s). "
        }
        
        if !structuredInfo.keyValuePairs.isEmpty {
            preview += "Contains key-value information. "
        }
        
        if let contactInfo = structuredInfo.contactInfo {
            if !contactInfo.emails.isEmpty {
                preview += "Contains email addresses. "
            }
            if !contactInfo.phoneNumbers.isEmpty {
                preview += "Contains phone numbers. "
            }
        }
        
        // Add OCR text if preview is still empty
        if preview.isEmpty {
            let text = results.ocrResults.text
            if !text.isEmpty {
                preview = String(text.prefix(150)).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
            }
        }
        
        return preview.isEmpty ? "Processed content with advanced AI analysis" : preview
    }
    
    private func determineContentType(from results: AdvancedProcessingResults) -> ContentType {
        let documentType = results.documentAnalysis.documentType
        
        switch documentType {
        case .document, .form:
            return results.ocrResults.text.count > 50 ? .mixed : .image
        case .receipt, .businessCard:
            return .mixed
        case .presentation:
            return .mixed
        case .table:
            return .pdf
        case .whiteboard:
            return .mixed
        case .screenshot:
            return .image
        case .photo:
            return .image
        case .unknown:
            return results.ocrResults.text.count > 20 ? .mixed : .image
        }
    }
    
    private func determineSourceApp(from source: String) -> AppSource {
        let lowercaseSource = source.lowercased()
        
        if lowercaseSource.contains("camera") {
            return .camera
        } else if lowercaseSource.contains("photo") {
            return .photos
        } else if lowercaseSource.contains("clipboard") {
            return .clipboard
        } else if lowercaseSource.contains("safari") {
            return .safari
        } else {
            return .other
        }
    }
    
    // MARK: - Knowledge Graph Integration
    private func updateKnowledgeGraph(with contentItem: ContentItem, results: AdvancedProcessingResults) async {
        // Extract entities and create graph nodes
        for entity in results.semanticAnalysis.entities {
            // This would create or update entity nodes in the knowledge graph
            print("Adding entity to knowledge graph: \(entity.text) (\(entity.type.displayName))")
        }
        
        // Create knowledge connections based on extracted relationships
        for connection in results.knowledgeConnections {
            print("Creating knowledge connection: \(connection.relationshipType.displayName)")
        }
        
        // Update graph with new content node
        // This would integrate with the GraphEngine to build semantic connections
    }
    
    // MARK: - Intelligent Task Management
    private func saveIntelligentTasks(_ tasks: [IntelligentTask], sourceContentId: UUID) async {
        for task in tasks {
            // Convert IntelligentTask to SimpleTaskItem for compatibility
            let simpleTask = SimpleTaskItem(
                title: task.title,
                description: task.description,
                isCompleted: false,
                priority: convertPriority(task.predictedPriority),
                dueDate: task.suggestedDueDate
            )
            
            // TODO: Save to TaskManager when available
            print("Generated intelligent task: \(task.title) (Priority: \(task.predictedPriority.displayName), Confidence: \(Int(task.confidenceScore * 100))%)")
            
            // Log contextual reasons for task generation
            for reason in task.contextualReasons {
                print("  Reason: \(reason)")
            }
        }
    }
    
    private func convertPriority(_ aiPriority: IntelligentTask.TaskPriority) -> SimpleTaskItem.TaskPriority {
        switch aiPriority {
        case .low:
            return .low
        case .medium:
            return .medium
        case .high:
            return .high
        case .urgent:
            return .high // Map urgent to high as SimpleTaskItem doesn't have urgent
        }
    }
    
    // MARK: - Task Generation from Content
    private func generateTasks(from text: String, aiResults: AIProcessingResults) async throws -> [SimpleTaskItem] {
        // Simulate task generation processing
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        var tasks: [SimpleTaskItem] = []
        
        // Smart task generation based on extracted content
        let actionWords = ["review", "complete", "follow up", "schedule", "call", "email", "submit", "finish"]
        let words = text.lowercased().components(separatedBy: CharacterSet.whitespacesAndNewlines)
        
        for actionWord in actionWords {
            if words.contains(actionWord) {
                let task = SimpleTaskItem(
                    title: "Action: \(actionWord.capitalized) from screenshot",
                    description: "Generated from image content analysis",
                    isCompleted: false,
                    priority: aiResults.confidence > 0.8 ? .high : .medium,
                    dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())
                )
                tasks.append(task)
            }
        }
        
        // Generate a general review task for any screenshot
        if !text.isEmpty && tasks.isEmpty {
            let reviewTask = SimpleTaskItem(
                title: "Review captured content",
                description: "Review and organize content from screenshot: \(String(text.prefix(50)))",
                isCompleted: false,
                priority: .low,
                dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
            )
            tasks.append(reviewTask)
        }
        
        return tasks
    }
    
    // MARK: - Content Item Creation
    private func createContentItem(
        imageData: Data,
        extractedText: String,
        aiResults: AIProcessingResults,
        tasks: [SimpleTaskItem],
        source: String
    ) async throws -> ContentItem {
        
        let title = generateSmartTitle(from: extractedText, aiResults: aiResults)
        let preview = generatePreview(from: extractedText)
        
        // Determine content type based on analysis
        let contentType: ContentType = {
            if extractedText.count > 50 {
                return .mixed // Image with substantial text
            } else if aiResults.detectedObjects.contains(where: { $0.label.contains("document") }) {
                return .pdf
            } else {
                return .image
            }
        }()
        
        // Create attachments (thumbnail and full image)
        let attachments = try await createAttachments(from: imageData)
        
        return ContentItem(
            id: UUID(),
            title: title,
            preview: preview,
            source: source,
            sourceApp: AppSource.camera, // or .screenshot
            type: contentType,
            isFavorite: false,
            timestamp: Date(),
            attachments: attachments,
            processingStatus: "completed"
        )
    }
    
    // MARK: - Helper Methods
    private func generateSmartTitle(from text: String, aiResults: AIProcessingResults) -> String {
        // Use first line of text or AI-detected content
        if !text.isEmpty {
            let firstLine = text.components(separatedBy: .newlines).first ?? ""
            if !firstLine.isEmpty && firstLine.count <= 60 {
                return firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Fallback to AI-detected objects
        if let mainObject = aiResults.detectedObjects.first {
            return "Screenshot: \(mainObject.label)"
        }
        
        return "Screenshot from \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))"
    }
    
    private func generatePreview(from text: String) -> String {
        if text.isEmpty {
            return "Processed screenshot with AI analysis"
        }
        
        return String(text.prefix(200)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func createAttachments(from imageData: Data) async throws -> [AttachmentPreview] {
        // TODO: Integrate with existing ImageProcessor to create thumbnails
        return []
    }
}

// MARK: - AI Processing Results Extension
extension AIProcessingResults {
    var taskPriority: SimpleTaskItem.TaskPriority {
        let highConfidenceObjects = detectedObjects.filter { $0.confidence > 0.8 }
        let urgentKeywords = ["urgent", "important", "asap", "deadline", "due"]
        
        if let text = extractedText, urgentKeywords.contains(where: { keyword in
            text.localizedCaseInsensitiveContains(keyword)
        }) {
            return .high
        } else if highConfidenceObjects.count > 2 {
            return .medium
        } else {
            return .low
        }
    }
}