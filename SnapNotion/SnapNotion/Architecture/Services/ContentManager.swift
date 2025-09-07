//
//  ContentManager.swift
//  SnapNotion
//
//  Centralized content management service bridging UI and Core Data
//  Created by A. C. on 9/7/25.
//

import Foundation
import CoreData
import SwiftUI
import Vision
import UniformTypeIdentifiers
import PDFKit
import os.log

@MainActor
class ContentManager: ObservableObject {
    
    static let shared = ContentManager()
    
    @Published var allContent: [ContentNodeData] = []
    @Published var isProcessing = false
    @Published var lastError: Error?
    
    private let logger = Logger(subsystem: "com.snapnotion.content", category: "ContentManager")
    private let persistenceController = PersistenceController.shared
    private let aiAnalyzer = AdvancedAIContentAnalyzer.shared
    private let taggingEngine = SemanticTaggingEngine.shared
    private let taskGenerator = TaskGenerationEngine.shared
    private let searchEngine = SemanticSearchEngine.shared
    
    private init() {
        loadAllContent()
        
        // Listen for Core Data remote change notifications
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadAllContent()
        }
    }
    
    // MARK: - Content Loading
    
    func loadAllContent() {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<ContentNode> = ContentNode.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ContentNode.createdAt, ascending: false)]
        
        do {
            let nodes = try context.fetch(request)
            self.allContent = nodes.compactMap { convertToContentNodeData($0) }
            logger.info("Loaded \(self.allContent.count) content items")
        } catch {
            logger.error("Failed to load content: \(error.localizedDescription)")
            self.lastError = error
        }
    }
    
    // MARK: - Content Creation
    
    func createContentFromCamera(image: UIImage) async throws -> ContentNodeData {
        isProcessing = true
        defer { isProcessing = false }
        
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let contentData = try await processImageContent(image, source: .camera)
                    let savedContent = try await saveContentNode(contentData)
                    continuation.resume(returning: savedContent)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func createContentFromPhotoLibrary(image: UIImage) async throws -> ContentNodeData {
        isProcessing = true
        defer { isProcessing = false }
        
        let contentData = try await processImageContent(image, source: .photoLibrary)
        return try await saveContentNode(contentData)
    }
    
    func createContentFromText(_ text: String) async throws -> ContentNodeData {
        isProcessing = true
        defer { isProcessing = false }
        
        let contentData = ContentNodeData(
            id: UUID(),
            title: extractTitle(from: text),
            preview: String(text.prefix(200)),
            contentText: text,
            type: .text,
            timestamp: Date(),
            source: "manual_entry",
            isFavorite: false,
            processingStatus: .completed,
            aiConfidence: 1.0
        )
        
        return try await saveContentNode(contentData)
    }
    
    func createContentFromURL(_ url: URL) async throws -> ContentNodeData {
        isProcessing = true
        defer { isProcessing = false }
        
        let contentData = try await processURLContent(url)
        return try await saveContentNode(contentData)
    }
    
    func createContentFromClipboard() async throws -> ContentNodeData? {
        isProcessing = true
        defer { isProcessing = false }
        
        guard let clipboardContent = await processClipboardContent() else {
            return nil
        }
        
        return try await saveContentNode(clipboardContent)
    }
    
    func createContentFromFile(at url: URL) async throws -> ContentNodeData {
        isProcessing = true
        defer { isProcessing = false }
        
        let contentData = try await processFileContent(url)
        return try await saveContentNode(contentData)
    }
    
    // MARK: - Content Processing
    
    private func processImageContent(_ image: UIImage, source: ContentSource) async throws -> ContentNodeData {
        // Extract OCR text
        let ocrText = try await performOCR(on: image)
        
        // Convert image to data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ContentError.imageProcessingFailed
        }
        
        let title = extractTitle(from: ocrText) 
        let preview = ocrText.isEmpty ? "Image content" : String(ocrText.prefix(200))
        
        return ContentNodeData(
            id: UUID(),
            title: title,
            preview: preview,
            contentText: ocrText,
            type: .image,
            timestamp: Date(),
            source: source.rawValue,
            isFavorite: false,
            processingStatus: .completed,
            aiConfidence: ocrText.isEmpty ? 0.1 : 0.8,
            imageData: imageData,
            ocrText: ocrText
        )
    }
    
    private func processURLContent(_ url: URL) async throws -> ContentNodeData {
        // Basic URL content processing - would be enhanced with web scraping
        let title = url.lastPathComponent
        let preview = url.absoluteString
        
        return ContentNodeData(
            id: UUID(),
            title: title,
            preview: preview,
            contentText: url.absoluteString,
            type: .web,
            timestamp: Date(),
            source: "url_import",
            sourceURL: url.absoluteString,
            isFavorite: false,
            processingStatus: .completed,
            aiConfidence: 0.5
        )
    }
    
    private func processClipboardContent() async -> ContentNodeData? {
        let pasteboard = UIPasteboard.general
        
        // Check for image in clipboard
        if let image = pasteboard.image {
            do {
                return try await processImageContent(image, source: .clipboard)
            } catch {
                logger.error("Failed to process clipboard image: \(error.localizedDescription)")
                return nil
            }
        }
        
        // Check for text in clipboard
        if let text = pasteboard.string, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let title = extractTitle(from: text)
            let preview = String(text.prefix(200))
            
            return ContentNodeData(
                id: UUID(),
                title: title,
                preview: preview,
                contentText: text,
                type: .text,
                timestamp: Date(),
                source: "clipboard",
                isFavorite: false,
                processingStatus: .completed,
                aiConfidence: 0.9
            )
        }
        
        // Check for URL in clipboard
        if let url = pasteboard.url {
            do {
                return try await processURLContent(url)
            } catch {
                logger.error("Failed to process clipboard URL: \(error.localizedDescription)")
                return nil
            }
        }
        
        return nil
    }
    
    private func processFileContent(_ url: URL) async throws -> ContentNodeData {
        let fileType = url.pathExtension.lowercased()
        
        switch fileType {
        case "pdf":
            return try await processPDFContent(url)
        case "txt", "md", "rtf":
            return try await processTextFileContent(url)
        case "jpg", "jpeg", "png", "heic":
            return try await processImageFileContent(url)
        default:
            return try await processGenericFileContent(url)
        }
    }
    
    private func processPDFContent(_ url: URL) async throws -> ContentNodeData {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw ContentError.pdfProcessingFailed
        }
        
        var fullText = ""
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i),
               let pageText = page.string {
                fullText += pageText + "\n\n"
            }
        }
        
        let title = url.lastPathComponent
        let preview = String(fullText.prefix(200))
        
        return ContentNodeData(
            id: UUID(),
            title: title,
            preview: preview,
            contentText: fullText,
            type: .pdf,
            timestamp: Date(),
            source: "file_import",
            isFavorite: false,
            processingStatus: .completed,
            aiConfidence: 0.9
        )
    }
    
    private func processTextFileContent(_ url: URL) async throws -> ContentNodeData {
        let content = try String(contentsOf: url, encoding: .utf8)
        let title = url.lastPathComponent
        let preview = String(content.prefix(200))
        
        return ContentNodeData(
            id: UUID(),
            title: title,
            preview: preview,
            contentText: content,
            type: .text,
            timestamp: Date(),
            source: "file_import",
            isFavorite: false,
            processingStatus: .completed,
            aiConfidence: 1.0
        )
    }
    
    private func processImageFileContent(_ url: URL) async throws -> ContentNodeData {
        guard let image = UIImage(contentsOfFile: url.path) else {
            throw ContentError.imageProcessingFailed
        }
        
        return try await processImageContent(image, source: .fileImport)
    }
    
    private func processGenericFileContent(_ url: URL) async throws -> ContentNodeData {
        let title = url.lastPathComponent
        let preview = "File: \(title)"
        
        return ContentNodeData(
            id: UUID(),
            title: title,
            preview: preview,
            contentText: "",
            type: .mixed,
            timestamp: Date(),
            source: "file_import",
            isFavorite: false,
            processingStatus: .pending,
            aiConfidence: 0.3
        )
    }
    
    // MARK: - OCR Processing
    
    private func performOCR(on image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw ContentError.imageProcessingFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let requestHandler = VNImageRequestHandler(cgImage: cgImage)
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let recognizedStrings = request.results?.compactMap { result in
                    (result as? VNRecognizedTextObservation)?.topCandidates(1).first?.string
                } ?? []
                
                let fullText = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }
            
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US", "zh-CN"]
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Core Data Operations
    
    private func saveContentNode(_ contentData: ContentNodeData) async throws -> ContentNodeData {
        return try await persistenceController.performBackgroundTask { context in
            let entity = ContentNode(context: context)
            entity.id = contentData.id
            entity.title = contentData.title
            entity.contentText = contentData.contentText
            entity.contentType = contentData.type.rawValue
            entity.sourceApp = contentData.source
            entity.sourceURL = contentData.sourceURL
            entity.createdAt = contentData.timestamp
            entity.modifiedAt = contentData.timestamp
            entity.isFavorite = contentData.isFavorite
            entity.processingStatus = contentData.processingStatus.rawValue
            entity.aiConfidence = contentData.aiConfidence ?? 0.0
            entity.ocrText = contentData.ocrText
            
            if let imageData = contentData.imageData {
                entity.contentData = imageData
            }
            
            try context.save()
            
            // Reload content on main actor
            DispatchQueue.main.async {
                self.loadAllContent()
            }
            
            // Trigger AI processing in background
            Task {
                await self.processContentWithAI(contentData)
            }
            
            return contentData
        }
    }
    
    // MARK: - Helper Functions
    
    private func extractTitle(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Untitled" }
        
        // Take first line or first 50 characters
        let firstLine = trimmed.components(separatedBy: .newlines).first ?? ""
        let title = String(firstLine.prefix(50))
        return title.isEmpty ? "Untitled" : title
    }
    
    // MARK: - AI Processing Integration
    
    private func processContentWithAI(_ content: ContentNodeData) async {
        do {
            logger.info("Starting AI processing for content: \(content.id)")
            
            // 1. AI Content Analysis
            let analysis = try await aiAnalyzer.analyzeContent(content)
            logger.info("AI analysis completed with confidence: \(analysis.confidence)")
            
            // 2. Generate Semantic Tags
            let semanticTags = await taggingEngine.generateSemanticTags(for: content)
            logger.info("Generated \(semanticTags.count) semantic tags")
            
            // 3. Generate Tasks
            let generatedTasks = try await taskGenerator.generateTasksFromContent(content)
            logger.info("Generated \(generatedTasks.count) tasks")
            
            // 4. Update Search Index
            await searchEngine.updateSearchIndex(for: content.id, content: content)
            logger.info("Updated search index")
            
            // 5. Store AI results in Core Data (could be enhanced to store analysis results)
            await storeAIResults(contentId: content.id, analysis: analysis, tags: semanticTags, tasks: generatedTasks)
            
            logger.info("AI processing completed for content: \(content.id)")
            
        } catch {
            logger.error("AI processing failed for content \(content.id): \(error.localizedDescription)")
            await MainActor.run {
                self.lastError = error
            }
        }
    }
    
    private func storeAIResults(contentId: UUID, analysis: ContentAnalysis, tags: [SemanticTag], tasks: [AIGeneratedTask]) async {
        // TODO: Store AI analysis results, tags, and generated tasks in Core Data
        // This would involve creating additional Core Data entities for:
        // - ContentAnalysis
        // - SemanticTags
        // - GeneratedTasks
        
        logger.info("AI results stored for content: \(contentId)")
        logger.info("- Analysis confidence: \(analysis.confidence)")
        logger.info("- Tags: \(tags.count)")
        logger.info("- Tasks: \(tasks.count)")
        logger.info("- Summary: \(analysis.summary)")
        
        // Apply tags to tagging engine
        taggingEngine.applyTagsToContent(contentId, tags: tags)
    }
    
    private func convertToContentNodeData(_ node: ContentNode) -> ContentNodeData? {
        guard let id = node.id,
              let createdAt = node.createdAt,
              let type = ContentType(rawValue: node.contentType ?? "") else {
            return nil
        }
        
        return ContentNodeData(
            id: id,
            title: node.title ?? "Untitled",
            preview: String((node.contentText ?? "").prefix(200)),
            contentText: node.contentText,
            type: type,
            timestamp: createdAt,
            source: node.sourceApp ?? "unknown",
            sourceURL: node.sourceURL,
            isFavorite: node.isFavorite,
            processingStatus: ProcessingStatusType(rawValue: node.processingStatus ?? "") ?? .pending,
            aiConfidence: node.aiConfidence,
            imageData: node.contentData,
            ocrText: node.ocrText
        )
    }
}

// MARK: - Supporting Types

enum ContentSource: String {
    case camera = "camera"
    case photoLibrary = "photo_library"
    case clipboard = "clipboard"
    case fileImport = "file_import"
    case manualEntry = "manual_entry"
    case urlImport = "url_import"
}

enum ContentError: Error, LocalizedError {
    case imageProcessingFailed
    case pdfProcessingFailed
    case fileAccessDenied
    case networkError
    case processingTimeout
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process image content"
        case .pdfProcessingFailed:
            return "Failed to process PDF content"
        case .fileAccessDenied:
            return "File access denied"
        case .networkError:
            return "Network error occurred"
        case .processingTimeout:
            return "Processing timeout"
        }
    }
}

// MARK: - ContentNodeData Definition

struct ContentNodeData: Identifiable, Hashable {
    let id: UUID
    let title: String
    let preview: String
    let contentText: String?
    let type: ContentType
    let timestamp: Date
    let source: String
    let sourceURL: String?
    let isFavorite: Bool
    let processingStatus: ProcessingStatusType
    let aiConfidence: Double?
    let imageData: Data?
    let ocrText: String?
    
    init(id: UUID, title: String, preview: String, contentText: String? = nil, type: ContentType, timestamp: Date, source: String, sourceURL: String? = nil, isFavorite: Bool = false, processingStatus: ProcessingStatusType = .pending, aiConfidence: Double? = nil, imageData: Data? = nil, ocrText: String? = nil) {
        self.id = id
        self.title = title
        self.preview = preview
        self.contentText = contentText
        self.type = type
        self.timestamp = timestamp
        self.source = source
        self.sourceURL = sourceURL
        self.isFavorite = isFavorite
        self.processingStatus = processingStatus
        self.aiConfidence = aiConfidence
        self.imageData = imageData
        self.ocrText = ocrText
    }
}

// ProcessingStatus and ContentType are defined in SimpleModels.swift