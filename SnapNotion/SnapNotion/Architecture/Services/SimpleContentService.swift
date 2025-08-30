//
//  SimpleContentService.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import Foundation

// MARK: - Simple Content Service Implementation
class SimpleContentService: ContentServiceProtocol {
    
    static let shared = SimpleContentService()
    
    private var contentItems: [ContentItem] = ContentItem.sampleData
    
    private init() {}
    
    func fetchContent(page: Int, pageSize: Int, filter: ContentFilter, searchQuery: String?) async throws -> [ContentItem] {
        var filtered = contentItems
        
        // Apply search filter if provided
        if let query = searchQuery, !query.isEmpty {
            filtered = filtered.filter { item in
                item.title.localizedCaseInsensitiveContains(query) ||
                item.preview.localizedCaseInsensitiveContains(query) ||
                item.source.localizedCaseInsensitiveContains(query)
            }
        }
        
        // Apply content filter
        switch filter {
        case .all:
            break
        case .favorites:
            filtered = filtered.filter { $0.isFavorite }
        case .images:
            filtered = filtered.filter { $0.type == .image }
        case .documents:
            filtered = filtered.filter { $0.type == .pdf || $0.type == .text }
        case .web:
            filtered = filtered.filter { $0.type == .web }
        case .bySource(let source):
            filtered = filtered.filter { $0.source == source.displayName }
        }
        
        // Apply pagination
        let startIndex = page * pageSize
        let endIndex = min(startIndex + pageSize, filtered.count)
        
        guard startIndex < filtered.count else {
            return []
        }
        
        return Array(filtered[startIndex..<endIndex])
    }
    
    func processSharedContent(_ content: SharedContent) async throws -> ContentItem {
        let newItem = ContentItem(
            id: content.id,
            title: generateTitle(from: content),
            preview: generatePreview(from: content),
            source: content.sourceApp.displayName,
            type: content.type,
            isFavorite: false,
            timestamp: content.timestamp
        )
        
        contentItems.insert(newItem, at: 0)
        return newItem
    }
    
    func toggleFavorite(itemId: UUID) async throws {
        if let index = contentItems.firstIndex(where: { $0.id == itemId }) {
            let item = contentItems[index]
            let updatedItem = ContentItem(
                id: item.id,
                title: item.title,
                preview: item.preview,
                source: item.source,
                type: item.type,
                isFavorite: !item.isFavorite,
                timestamp: item.timestamp
            )
            contentItems[index] = updatedItem
        }
    }
    
    func deleteContent(itemId: UUID) async throws {
        contentItems.removeAll { $0.id == itemId }
    }
    
    // MARK: - Helper Methods
    private func generateTitle(from content: SharedContent) -> String {
        if let text = content.text, !text.isEmpty {
            let words = text.components(separatedBy: CharacterSet.whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .prefix(6)
            return words.joined(separator: " ")
        } else if let url = content.url {
            return url.lastPathComponent
        } else {
            return "Content from \(content.sourceApp.displayName)"
        }
    }
    
    private func generatePreview(from content: SharedContent) -> String {
        if let text = content.text, !text.isEmpty {
            return String(text.prefix(200))
        } else if let url = content.url {
            return "URL: \(url.absoluteString)"
        } else if content.data != nil {
            return "\(content.type.rawValue.capitalized) content (\(ByteCountFormatter.string(fromByteCount: Int64(content.data?.count ?? 0), countStyle: .file)))"
        } else {
            return "Content from \(content.sourceApp.displayName)"
        }
    }
}