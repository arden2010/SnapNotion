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
    
    func fetchAllContent() async throws -> [ContentItem] {
        return contentItems
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