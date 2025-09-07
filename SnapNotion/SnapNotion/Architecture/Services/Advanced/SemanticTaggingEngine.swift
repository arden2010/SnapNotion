//
//  SemanticTaggingEngine.swift
//  SnapNotion
//
//  Advanced semantic tagging and content categorization system
//  Created by A. C. on 9/7/25.
//

import Foundation
import NaturalLanguage
import SwiftUI
import os.log

@MainActor
class SemanticTaggingEngine: ObservableObject {
    
    static let shared = SemanticTaggingEngine()
    
    @Published var isProcessingTags = false
    @Published var tagSuggestions: [TagSuggestion] = []
    
    private let logger = Logger(subsystem: "com.snapnotion.semantic", category: "TaggingEngine")
    private let aiAnalyzer = AIContentAnalyzer.shared
    
    // Predefined tag hierarchies for better organization
    private let tagHierarchies: [String: [String]] = [
        "work": ["project", "meeting", "deadline", "client", "presentation", "report"],
        "personal": ["shopping", "health", "family", "friends", "hobbies", "travel"],
        "learning": ["course", "tutorial", "research", "book", "article", "notes"],
        "finance": ["budget", "expense", "invoice", "tax", "investment", "bill"],
        "health": ["appointment", "medication", "exercise", "diet", "wellness"],
        "travel": ["flight", "hotel", "itinerary", "destination", "booking", "vacation"]
    ]
    
    // MARK: - Core Tagging Functions
    
    func generateSemanticTags(for content: ContentNodeData) async -> [SemanticTag] {
        isProcessingTags = true
        defer { isProcessingTags = false }
        
        logger.info("Generating semantic tags for content: \(content.id)")
        
        do {
            // Get AI analysis first
            let analysis = try await aiAnalyzer.analyzeContent(content)
            
            var tags: [SemanticTag] = []
            
            // 1. Category-based tags
            tags.append(contentsOf: createCategoryTags(analysis.category))
            
            // 2. Keyword-based tags
            tags.append(contentsOf: createKeywordTags(analysis.keywords))
            
            // 3. Entity-based tags
            tags.append(contentsOf: createEntityTags(analysis.entities))
            
            // 4. Context-based tags
            tags.append(contentsOf: createContextTags(content, analysis: analysis))
            
            // 5. Hierarchical tags
            tags.append(contentsOf: createHierarchicalTags(tags))
            
            // 6. Sentiment-based tags
            tags.append(contentsOf: createSentimentTags(analysis.sentiment))
            
            // Remove duplicates and sort by relevance
            let uniqueTags = Array(Set(tags)).sorted { $0.relevanceScore > $1.relevanceScore }
            
            logger.info("Generated \(uniqueTags.count) semantic tags")
            return Array(uniqueTags.prefix(15)) // Limit to top 15 tags
            
        } catch {
            logger.error("Failed to generate semantic tags: \(error.localizedDescription)")
            return createFallbackTags(content)
        }
    }
    
    func suggestTagsForQuery(_ query: String) -> [TagSuggestion] {
        let normalizedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        var suggestions: [TagSuggestion] = []
        
        // Search in tag hierarchies
        for (parentTag, childTags) in tagHierarchies {
            if parentTag.contains(normalizedQuery) {
                suggestions.append(TagSuggestion(
                    tag: parentTag,
                    confidence: 0.9,
                    category: .hierarchy,
                    relatedTags: childTags
                ))
            }
            
            for childTag in childTags where childTag.contains(normalizedQuery) {
                suggestions.append(TagSuggestion(
                    tag: childTag,
                    confidence: 0.8,
                    category: .keyword,
                    relatedTags: [parentTag]
                ))
            }
        }
        
        // Add content type based suggestions
        if normalizedQuery.contains("image") || normalizedQuery.contains("photo") {
            suggestions.append(TagSuggestion(
                tag: "visual",
                confidence: 0.7,
                category: .contentType,
                relatedTags: ["image", "photo", "graphic"]
            ))
        }
        
        return suggestions.sorted { $0.confidence > $1.confidence }
    }
    
    // MARK: - Tag Creation Methods
    
    private func createCategoryTags(_ category: AIContentCategory) -> [SemanticTag] {
        let tag = SemanticTag(
            name: category.rawValue,
            type: .category,
            relevanceScore: 0.9,
            confidence: 0.95,
            source: .ai,
            metadata: ["category": category.rawValue]
        )
        return [tag]
    }
    
    private func createKeywordTags(_ keywords: [String]) -> [SemanticTag] {
        return keywords.enumerated().map { index, keyword in
            SemanticTag(
                name: keyword,
                type: .keyword,
                relevanceScore: 0.8 - (Double(index) * 0.1),
                confidence: 0.7,
                source: .nlp,
                metadata: ["keyword": keyword]
            )
        }
    }
    
    private func createEntityTags(_ entities: [NamedEntity]) -> [SemanticTag] {
        return entities.map { entity in
            SemanticTag(
                name: entity.text.lowercased(),
                type: .entity,
                relevanceScore: 0.75,
                confidence: entity.confidence,
                source: .nlp,
                metadata: [
                    "entity": entity.text,
                    "entityType": entity.type.rawValue
                ]
            )
        }
    }
    
    private func createContextTags(_ content: ContentNodeData, analysis: ContentAnalysis) -> [SemanticTag] {
        var tags: [SemanticTag] = []
        
        // Source-based tags
        let sourceTag = SemanticTag(
            name: content.source,
            type: .source,
            relevanceScore: 0.6,
            confidence: 1.0,
            source: .system,
            metadata: ["source": content.source]
        )
        tags.append(sourceTag)
        
        // Content type tags
        let typeTag = SemanticTag(
            name: content.type.rawValue,
            type: .contentType,
            relevanceScore: 0.7,
            confidence: 1.0,
            source: .system,
            metadata: ["contentType": content.type.rawValue]
        )
        tags.append(typeTag)
        
        // Time-based tags
        let timeTag = createTimeBasedTag(content.timestamp)
        tags.append(timeTag)
        
        // Priority-based tags
        if analysis.priority == .high {
            tags.append(SemanticTag(
                name: "urgent",
                type: .priority,
                relevanceScore: 0.8,
                confidence: 0.8,
                source: .ai,
                metadata: ["priority": "high"]
            ))
        }
        
        return tags
    }
    
    private func createHierarchicalTags(_ existingTags: [SemanticTag]) -> [SemanticTag] {
        var hierarchicalTags: [SemanticTag] = []
        
        for tag in existingTags {
            // Find parent tags in hierarchy
            for (parentTag, childTags) in tagHierarchies {
                if childTags.contains(tag.name) {
                    hierarchicalTags.append(SemanticTag(
                        name: parentTag,
                        type: .hierarchy,
                        relevanceScore: 0.5,
                        confidence: 0.6,
                        source: .system,
                        metadata: [
                            "parent": parentTag,
                            "child": tag.name
                        ]
                    ))
                }
            }
        }
        
        return hierarchicalTags
    }
    
    private func createSentimentTags(_ sentiment: SentimentScore) -> [SemanticTag] {
        var tags: [SemanticTag] = []
        
        if sentiment.positive > 0.7 {
            tags.append(SemanticTag(
                name: "positive",
                type: .sentiment,
                relevanceScore: 0.4,
                confidence: sentiment.positive,
                source: .ai,
                metadata: ["sentiment": "positive"]
            ))
        } else if sentiment.negative > 0.7 {
            tags.append(SemanticTag(
                name: "negative",
                type: .sentiment,
                relevanceScore: 0.4,
                confidence: sentiment.negative,
                source: .ai,
                metadata: ["sentiment": "negative"]
            ))
        }
        
        return tags
    }
    
    private func createTimeBasedTag(_ timestamp: Date) -> SemanticTag {
        let calendar = Calendar.current
        let now = Date()
        
        let tagName: String
        if calendar.isDateInToday(timestamp) {
            tagName = "today"
        } else if calendar.isDateInYesterday(timestamp) {
            tagName = "yesterday"
        } else if calendar.isDate(timestamp, equalTo: now, toGranularity: .weekOfYear) {
            tagName = "this-week"
        } else if calendar.isDate(timestamp, equalTo: now, toGranularity: .month) {
            tagName = "this-month"
        } else {
            tagName = "older"
        }
        
        return SemanticTag(
            name: tagName,
            type: .temporal,
            relevanceScore: 0.3,
            confidence: 1.0,
            source: .system,
            metadata: ["timeframe": tagName]
        )
    }
    
    private func createFallbackTags(_ content: ContentNodeData) -> [SemanticTag] {
        // Basic fallback tags when AI analysis fails
        let basicTags = [
            SemanticTag(
                name: content.type.rawValue,
                type: .contentType,
                relevanceScore: 0.8,
                confidence: 1.0,
                source: .system,
                metadata: ["contentType": content.type.rawValue]
            ),
            SemanticTag(
                name: content.source,
                type: .source,
                relevanceScore: 0.6,
                confidence: 1.0,
                source: .system,
                metadata: ["source": content.source]
            )
        ]
        
        return basicTags
    }
    
    // MARK: - Tag Management
    
    func applyTagsToContent(_ contentId: UUID, tags: [SemanticTag]) {
        // TODO: Save tags to Core Data
        logger.info("Applied \(tags.count) tags to content \(contentId)")
    }
    
    func searchContentByTags(_ tags: [String]) -> [UUID] {
        // TODO: Implement tag-based content search
        logger.info("Searching content by tags: \(tags.joined(separator: ", "))")
        return []
    }
    
    func getTagStatistics() -> TagStatistics {
        // TODO: Calculate tag usage statistics
        return TagStatistics(
            totalTags: 0,
            mostUsedTags: [],
            recentTags: [],
            tagCategories: [:]
        )
    }
}

// MARK: - Supporting Data Models

struct SemanticTag: Identifiable, Hashable, Codable {
    let id = UUID()
    let name: String
    let type: TagType
    let relevanceScore: Double
    let confidence: Double
    let source: TagSource
    let metadata: [String: String]
    
    // Custom hash implementation for Set operations
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(type)
    }
    
    static func == (lhs: SemanticTag, rhs: SemanticTag) -> Bool {
        return lhs.name == rhs.name && lhs.type == rhs.type
    }
}

enum TagType: String, CaseIterable, Codable {
    case category = "category"
    case keyword = "keyword"
    case entity = "entity"
    case source = "source"
    case contentType = "contentType"
    case temporal = "temporal"
    case hierarchy = "hierarchy"
    case priority = "priority"
    case sentiment = "sentiment"
    case custom = "custom"
}

enum TagSource: String, CaseIterable, Codable {
    case ai = "ai"
    case nlp = "nlp"
    case system = "system"
    case user = "user"
}

struct TagSuggestion: Identifiable, Codable {
    let id = UUID()
    let tag: String
    let confidence: Double
    let category: TagSuggestionCategory
    let relatedTags: [String]
}

enum TagSuggestionCategory: String, CaseIterable, Codable {
    case hierarchy = "hierarchy"
    case keyword = "keyword"
    case contentType = "contentType"
    case similar = "similar"
}

struct TagStatistics: Codable {
    let totalTags: Int
    let mostUsedTags: [TagUsage]
    let recentTags: [String]
    let tagCategories: [String: Int]
}

struct TagUsage: Identifiable, Codable {
    let id = UUID()
    let tag: String
    let count: Int
    let lastUsed: Date
}