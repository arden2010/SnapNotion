//
//  ContentService.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import Foundation
import CoreData
import Combine

// MARK: - Content Service Protocol
protocol ContentServiceProtocol {
    func fetchAllContent() async throws -> [ContentItem]
    func fetchContent(by filter: ContentFilter) async throws -> [ContentItem]
    func saveContent(_ item: ContentItem) async throws -> ContentItem
    func updateContent(_ item: ContentItem) async throws -> ContentItem
    func deleteContent(itemId: UUID) async throws
    func toggleFavorite(itemId: UUID) async throws
    func processSharedContent(_ content: SharedContent) async throws -> ContentItem
    func searchContent(query: String) async throws -> [ContentItem]
}

// MARK: - Content Service Implementation
@MainActor
class ContentService: ContentServiceProtocol {
    
    static let shared = ContentService()
    
    // MARK: - Private Properties
    private let persistenceController: PersistenceController
    private let aiProcessor: AIProcessorProtocol
    private let imageProcessor: ImageProcessorProtocol
    
    // MARK: - Initialization
    init(
        persistenceController: PersistenceController = PersistenceController.shared,
        aiProcessor: AIProcessorProtocol = AIProcessor.shared,
        imageProcessor: ImageProcessorProtocol = ImageProcessor.shared
    ) {
        self.persistenceController = persistenceController
        self.aiProcessor = aiProcessor
        self.imageProcessor = imageProcessor
    }
    
    // MARK: - Public Methods
    func fetchAllContent() async throws -> [ContentItem] {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<ContentEntity> = ContentEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ContentEntity.timestamp, ascending: false)]
        
        let entities = try context.fetch(request)
        return entities.compactMap { $0.toContentItem() }
    }
    
    func fetchContent(by filter: ContentFilter) async throws -> [ContentItem] {
        let allContent = try await fetchAllContent()
        return applyFilter(filter, to: allContent)
    }
    
    func saveContent(_ item: ContentItem) async throws -> ContentItem {
        let context = persistenceController.container.viewContext
        let entity = ContentEntity(context: context)
        entity.populate(from: item)
        
        try context.save()
        return item
    }
    
    func updateContent(_ item: ContentItem) async throws -> ContentItem {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<ContentEntity> = ContentEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", item.id as CVarArg)
        
        guard let entity = try context.fetch(request).first else {
            throw ContentServiceError.itemNotFound
        }
        
        entity.populate(from: item)
        try context.save()
        return item
    }
    
    func deleteContent(itemId: UUID) async throws {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<ContentEntity> = ContentEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", itemId as CVarArg)
        
        guard let entity = try context.fetch(request).first else {
            throw ContentServiceError.itemNotFound
        }
        
        context.delete(entity)
        try context.save()
    }
    
    func toggleFavorite(itemId: UUID) async throws {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<ContentEntity> = ContentEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", itemId as CVarArg)
        
        guard let entity = try context.fetch(request).first else {
            throw ContentServiceError.itemNotFound
        }
        
        entity.isFavorite.toggle()
        try context.save()
    }
    
    func processSharedContent(_ content: SharedContent) async throws -> ContentItem {
        // Create initial content item
        var contentItem = ContentItem(
            title: extractTitle(from: content),
            preview: extractPreview(from: content),
            source: content.sourceApp.displayName,
            sourceApp: content.sourceApp,
            timestamp: Date(),
            type: content.type,
            isFavorite: false,
            attachments: [],
            metadata: ContentMetadata(),
            processingStatus: .processing
        )
        
        // Save initial item
        contentItem = try await saveContent(contentItem)
        
        // Process content asynchronously
        Task {
            await processContentInBackground(contentItem, sharedContent: content)
        }
        
        return contentItem
    }
    
    func searchContent(query: String) async throws -> [ContentItem] {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<ContentEntity> = ContentEntity.fetchRequest()
        
        let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", query)
        let previewPredicate = NSPredicate(format: "preview CONTAINS[cd] %@", query)
        let sourcePredicate = NSPredicate(format: "source CONTAINS[cd] %@", query)
        
        request.predicate = NSCompoundPredicate(
            orPredicateWithSubpredicates: [titlePredicate, previewPredicate, sourcePredicate]
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ContentEntity.timestamp, ascending: false)]
        
        let entities = try context.fetch(request)
        return entities.compactMap { $0.toContentItem() }
    }
    
    // MARK: - Private Methods
    private func applyFilter(_ filter: ContentFilter, to items: [ContentItem]) -> [ContentItem] {
        switch filter {
        case .all:
            return items
        case .favorites:
            return items.filter { $0.isFavorite }
        case .images:
            return items.filter { $0.type == .image || $0.type == .mixed }
        case .documents:
            return items.filter { $0.type == .pdf || $0.type == .text }
        case .web:
            return items.filter { $0.type == .web }
        case .bySource(let source):
            return items.filter { $0.sourceApp == source }
        }
    }
    
    private func extractTitle(from content: SharedContent) -> String {
        if let text = content.text, !text.isEmpty {
            let lines = text.components(separatedBy: .newlines)
            if let firstLine = lines.first, firstLine.count <= 100 {
                return firstLine
            }
            return String(text.prefix(100)) + "..."
        }
        
        if let url = content.url {
            return url.lastPathComponent
        }
        
        return "Shared from \(content.sourceApp.displayName)"
    }
    
    private func extractPreview(from content: SharedContent) -> String {
        if let text = content.text {
            return String(text.prefix(200))
        }
        
        if let url = content.url {
            return url.absoluteString
        }
        
        return "Content shared from \(content.sourceApp.displayName)"
    }
    
    private func processContentInBackground(_ item: ContentItem, sharedContent: SharedContent) async {
        do {
            var processedItem = item
            
            // Process based on content type
            switch sharedContent.type {
            case .image:
                if let data = sharedContent.data {
                    let imageResults = try await imageProcessor.processImage(data)
                    processedItem = updateItemWithImageResults(item, results: imageResults)
                }
            case .text:
                if let text = sharedContent.text {
                    let aiResults = try await aiProcessor.processText(text)
                    processedItem = updateItemWithAIResults(item, results: aiResults)
                }
            case .web:
                if let url = sharedContent.url {
                    let webResults = try await aiProcessor.processWebContent(url)
                    processedItem = updateItemWithWebResults(item, results: webResults)
                }
            default:
                break
            }
            
            // Update processing status
            processedItem = ContentItem(
                title: processedItem.title,
                preview: processedItem.preview,
                source: processedItem.source,
                sourceApp: processedItem.sourceApp,
                timestamp: processedItem.timestamp,
                type: processedItem.type,
                isFavorite: processedItem.isFavorite,
                attachments: processedItem.attachments,
                metadata: processedItem.metadata,
                processingStatus: .completed
            )
            
            try await updateContent(processedItem)
            
        } catch {
            // Update item with failed status
            let failedItem = ContentItem(
                title: item.title,
                preview: item.preview,
                source: item.source,
                sourceApp: item.sourceApp,
                timestamp: item.timestamp,
                type: item.type,
                isFavorite: item.isFavorite,
                attachments: item.attachments,
                metadata: item.metadata,
                processingStatus: .failed
            )
            
            try? await updateContent(failedItem)
        }
    }
    
    private func updateItemWithImageResults(_ item: ContentItem, results: ImageProcessingResults) -> ContentItem {
        let metadata = ContentMetadata(
            imageMetadata: results.metadata,
            aiProcessingResults: results.aiResults,
            extractedAt: Date()
        )
        
        return ContentItem(
            title: results.extractedTitle ?? item.title,
            preview: results.extractedText ?? item.preview,
            source: item.source,
            sourceApp: item.sourceApp,
            timestamp: item.timestamp,
            type: item.type,
            isFavorite: item.isFavorite,
            attachments: results.attachments,
            metadata: metadata,
            processingStatus: item.processingStatus
        )
    }
    
    private func updateItemWithAIResults(_ item: ContentItem, results: AIProcessingResults) -> ContentItem {
        let metadata = ContentMetadata(
            aiProcessingResults: results,
            extractedAt: Date()
        )
        
        return ContentItem(
            title: results.summary ?? item.title,
            preview: item.preview,
            source: item.source,
            sourceApp: item.sourceApp,
            timestamp: item.timestamp,
            type: item.type,
            isFavorite: item.isFavorite,
            attachments: item.attachments,
            metadata: metadata,
            processingStatus: item.processingStatus
        )
    }
    
    private func updateItemWithWebResults(_ item: ContentItem, results: WebProcessingResults) -> ContentItem {
        let metadata = ContentMetadata(
            originalURL: results.url,
            webMetadata: results.webMetadata,
            aiProcessingResults: results.aiResults,
            extractedAt: Date()
        )
        
        return ContentItem(
            title: results.webMetadata.title ?? item.title,
            preview: results.webMetadata.description ?? item.preview,
            source: results.webMetadata.siteName ?? item.source,
            sourceApp: item.sourceApp,
            timestamp: item.timestamp,
            type: item.type,
            isFavorite: item.isFavorite,
            attachments: [],
            metadata: metadata,
            processingStatus: item.processingStatus
        )
    }
}

// MARK: - Content Service Error
enum ContentServiceError: LocalizedError {
    case itemNotFound
    case processingFailed(String)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Content item not found"
        case .processingFailed(let reason):
            return "Processing failed: \(reason)"
        case .invalidData:
            return "Invalid data provided"
        }
    }
}

// MARK: - Processing Results
struct ImageProcessingResults {
    let metadata: ImageMetadata
    let extractedText: String?
    let extractedTitle: String?
    let aiResults: AIProcessingResults?
    let attachments: [AttachmentPreview]
}

struct WebProcessingResults {
    let url: URL
    let webMetadata: WebMetadata
    let aiResults: AIProcessingResults?
}