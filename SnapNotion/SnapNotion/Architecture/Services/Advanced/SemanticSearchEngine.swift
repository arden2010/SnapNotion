//
//  SemanticSearchEngine.swift
//  SnapNotion
//
//  Advanced semantic search with AI-powered content understanding
//  Created by A. C. on 9/7/25.
//

import Foundation
import NaturalLanguage
import SwiftUI
import CoreData
import os.log

@MainActor
class SemanticSearchEngine: ObservableObject {
    
    static let shared = SemanticSearchEngine()
    
    @Published var isSearching = false
    @Published var searchResults: [AIAISearchResult] = []
    @Published var searchSuggestions: [AISearchSuggestion] = []
    @Published var recentSearches: [String] = []
    
    private let logger = Logger(subsystem: "com.snapnotion.search", category: "SemanticSearch")
    private let aiAnalyzer = AIContentAnalyzer.shared
    private let taggingEngine = SemanticTaggingEngine.shared
    private let persistenceController = PersistenceController.shared
    
    // Search index for faster queries
    private var searchIndex: [UUID: SearchIndexEntry] = [:]
    private var isIndexBuilt = false
    
    // MARK: - Core Search Functions
    
    func search(_ query: String, filters: SearchFilters = SearchFilters()) async -> [AIAISearchResult] {
        isSearching = true
        defer { isSearching = false }
        
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return []
        }
        
        logger.info("Starting semantic search for: '\(query)'")
        
        // Build search index if needed
        if !isIndexBuilt {
            await buildSearchIndex()
        }
        
        // Add to recent searches
        addToRecentSearches(query)
        
        var results: [AIAISearchResult] = []
        
        // 1. Exact text matching (highest priority)
        results.append(contentsOf: await performTextSearch(query, filters: filters))
        
        // 2. Semantic similarity search
        results.append(contentsOf: await performSemanticSearch(query, filters: filters))
        
        // 3. Tag-based search
        results.append(contentsOf: await performTagSearch(query, filters: filters))
        
        // 4. AI-enhanced contextual search
        results.append(contentsOf: await performContextualSearch(query, filters: filters))
        
        // Remove duplicates and rank by relevance
        let uniqueResults = removeDuplicateResults(results)
        let rankedResults = rankAISearchResults(uniqueResults, query: query)
        
        searchResults = rankedResults
        
        logger.info("Search completed with \(rankedResults.count) results")
        return rankedResults
    }
    
    func generateAISearchSuggestions(_ partialQuery: String) -> [AISearchSuggestion] {
        guard partialQuery.count >= 2 else { return [] }
        
        var suggestions: [AISearchSuggestion] = []
        
        // 1. Recent searches
        suggestions.append(contentsOf: recentSearches
            .filter { $0.lowercased().contains(partialQuery.lowercased()) }
            .map { AISearchSuggestion(text: $0, type: .recent, confidence: 0.9) }
        )
        
        // 2. Tag suggestions
        suggestions.append(contentsOf: taggingEngine.suggestTagsForQuery(partialQuery)
            .map { AISearchSuggestion(text: $0.tag, type: .tag, confidence: $0.confidence) }
        )
        
        // 3. Content-based suggestions
        suggestions.append(contentsOf: generateContentSuggestions(partialQuery))
        
        // 4. Smart query completion
        suggestions.append(contentsOf: generateSmartCompletions(partialQuery))
        
        searchSuggestions = Array(Set(suggestions)).sorted { $0.confidence > $1.confidence }.prefix(10).map { $0 }
        return searchSuggestions
    }
    
    func performAdvancedSearch(_ query: AdvancedSearchQuery) async -> [AIAISearchResult] {
        isSearching = true
        defer { isSearching = false }
        
        logger.info("Performing advanced search")
        
        let results = await searchWithAdvancedCriteria(query)
        searchResults = results
        return results
    }
    
    // MARK: - Search Implementation Methods
    
    private func performTextSearch(_ query: String, filters: SearchFilters) async -> [AIAISearchResult] {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<ContentNode> = ContentNode.fetchRequest()
        
        // Build predicate for text search
        var predicates: [NSPredicate] = []
        
        // Text content search
        let textPredicate = NSPredicate(format: "contentText CONTAINS[cd] %@ OR title CONTAINS[cd] %@ OR ocrText CONTAINS[cd] %@", query, query, query)
        predicates.append(textPredicate)
        
        // Apply filters
        if let contentTypes = filters.contentTypes, !contentTypes.isEmpty {
            let typeStrings = contentTypes.map { $0.rawValue }
            let typePredicate = NSPredicate(format: "contentType IN %@", typeStrings)
            predicates.append(typePredicate)
        }
        
        if let dateRange = filters.dateRange {
            let datePredicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", dateRange.lowerBound as NSDate, dateRange.upperBound as NSDate)
            predicates.append(datePredicate)
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ContentNode.createdAt, ascending: false)]
        request.fetchLimit = 50
        
        do {
            let nodes = try context.fetch(request)
            return nodes.compactMap { node in
                createAISearchResult(from: node, query: query, searchType: .textMatch)
            }
        } catch {
            logger.error("Text search failed: \(error.localizedDescription)")
            return []
        }
    }
    
    private func performSemanticSearch(_ query: String, filters: SearchFilters) async -> [AIAISearchResult] {
        // Extract keywords and entities from query
        let queryKeywords = await extractKeywords(from: query)
        let queryEntities = await extractEntities(from: query)
        
        var semanticResults: [AIAISearchResult] = []
        
        // Search through indexed content
        for (contentId, indexEntry) in searchIndex {
            let semanticScore = calculateSemanticSimilarity(
                queryKeywords: queryKeywords,
                queryEntities: queryEntities,
                contentKeywords: indexEntry.keywords,
                contentEntities: indexEntry.entities
            )
            
            if semanticScore > 0.3 { // Minimum similarity threshold
                if let result = await createAISearchResultFromIndex(contentId: contentId, query: query, score: semanticScore, type: .semantic) {
                    semanticResults.append(result)
                }
            }
        }
        
        return semanticResults.sorted { $0.relevanceScore > $1.relevanceScore }
    }
    
    private func performTagSearch(_ query: String, filters: SearchFilters) async -> [AIAISearchResult] {
        // Search for content with tags matching the query
        let queryTags = query.lowercased().components(separatedBy: .whitespacesAndNewlines)
        var tagResults: [AIAISearchResult] = []
        
        for (contentId, indexEntry) in searchIndex {
            let matchingTags = indexEntry.tags.filter { tag in
                queryTags.contains { queryTag in
                    tag.lowercased().contains(queryTag) || queryTag.contains(tag.lowercased())
                }
            }
            
            if !matchingTags.isEmpty {
                let tagScore = Double(matchingTags.count) / Double(indexEntry.tags.count)
                if let result = await createAISearchResultFromIndex(contentId: contentId, query: query, score: tagScore, type: .tagMatch) {
                    tagResults.append(result)
                }
            }
        }
        
        return tagResults
    }
    
    private func performContextualSearch(_ query: String, filters: SearchFilters) async -> [AIAISearchResult] {
        // AI-enhanced contextual search using content analysis
        var contextualResults: [AIAISearchResult] = []
        
        do {
            // Analyze query intent
            let queryAnalysis = try await analyzeSearchQuery(query)
            
            // Search based on query intent
            for (contentId, indexEntry) in searchIndex {
                let contextScore = calculateContextualRelevance(queryAnalysis: queryAnalysis, indexEntry: indexEntry)
                
                if contextScore > 0.4 {
                    if let result = await createAISearchResultFromIndex(contentId: contentId, query: query, score: contextScore, type: .contextual) {
                        contextualResults.append(result)
                    }
                }
            }
        } catch {
            logger.error("Contextual search failed: \(error.localizedDescription)")
        }
        
        return contextualResults
    }
    
    // MARK: - Search Index Management
    
    private func buildSearchIndex() async {
        logger.info("Building search index")
        
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<ContentNode> = ContentNode.fetchRequest()
        
        do {
            let nodes = try context.fetch(request)
            
            for node in nodes {
                guard let id = node.id else { continue }
                
                let keywords = await extractKeywords(from: node.contentText ?? "")
                let entities = await extractEntities(from: node.ocrText ?? "")
                let tags = extractTagsFromNode(node)
                
                let indexEntry = SearchIndexEntry(
                    contentId: id,
                    title: node.title ?? "",
                    contentText: node.contentText ?? "",
                    ocrText: node.ocrText ?? "",
                    contentType: ContentType(rawValue: node.contentType ?? "") ?? .text,
                    keywords: keywords,
                    entities: entities.map { $0.text },
                    tags: tags,
                    createdAt: node.createdAt ?? Date(),
                    lastUpdated: Date()
                )
                
                searchIndex[id] = indexEntry
            }
            
            isIndexBuilt = true
            logger.info("Search index built with \(searchIndex.count) entries")
        } catch {
            logger.error("Failed to build search index: \(error.localizedDescription)")
        }
    }
    
    func updateSearchIndex(for contentId: UUID, content: ContentNodeData) async {
        let keywords = await extractKeywords(from: content.contentText ?? "")
        let entities = await extractEntities(from: content.ocrText ?? "")
        let tags = [content.source, content.type.rawValue] // Basic tags
        
        let indexEntry = SearchIndexEntry(
            contentId: contentId,
            title: content.title,
            contentText: content.contentText ?? "",
            ocrText: content.ocrText ?? "",
            contentType: content.type,
            keywords: keywords,
            entities: entities.map { $0.text },
            tags: tags,
            createdAt: content.timestamp,
            lastUpdated: Date()
        )
        
        searchIndex[contentId] = indexEntry
        logger.info("Updated search index for content: \(contentId)")
    }
    
    // MARK: - Helper Methods
    
    private func extractKeywords(from text: String) async -> [String] {
        guard !text.isEmpty else { return [] }
        
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var keywords: [String] = []
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            let word = String(text[tokenRange])
            
            if let tag = tag, tag == .noun || tag == .otherWord {
                if word.count > 3 && !isStopWord(word.lowercased()) {
                    keywords.append(word.lowercased())
                }
            }
            return true
        }
        
        // Return unique keywords
        return Array(Set(keywords))
    }
    
    private func extractEntities(from text: String) async -> [NamedEntity] {
        guard !text.isEmpty else { return [] }
        
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        var entities: [NamedEntity] = []
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            if let tag = tag {
                let entityText = String(text[tokenRange])
                let entityType: EntityType
                
                switch tag {
                case .personalName: entityType = .person
                case .placeName: entityType = .location
                case .organizationName: entityType = .organization
                default: entityType = .other
                }
                
                entities.append(NamedEntity(
                    text: entityText,
                    type: entityType,
                    confidence: 0.8,
                    range: text.distance(from: text.startIndex, to: tokenRange.lowerBound)
                ))
            }
            return true
        }
        
        return entities
    }
    
    private func calculateSemanticSimilarity(queryKeywords: [String], queryEntities: [NamedEntity], contentKeywords: [String], contentEntities: [String]) -> Double {
        // Keyword similarity (Jaccard similarity)
        let queryKeywordSet = Set(queryKeywords)
        let contentKeywordSet = Set(contentKeywords)
        let keywordIntersection = queryKeywordSet.intersection(contentKeywordSet)
        let keywordUnion = queryKeywordSet.union(contentKeywordSet)
        let keywordSimilarity = keywordUnion.isEmpty ? 0.0 : Double(keywordIntersection.count) / Double(keywordUnion.count)
        
        // Entity similarity
        let queryEntityTexts = Set(queryEntities.map { $0.text.lowercased() })
        let contentEntitySet = Set(contentEntities.map { $0.lowercased() })
        let entityIntersection = queryEntityTexts.intersection(contentEntitySet)
        let entityUnion = queryEntityTexts.union(contentEntitySet)
        let entitySimilarity = entityUnion.isEmpty ? 0.0 : Double(entityIntersection.count) / Double(entityUnion.count)
        
        // Weighted combination
        return (keywordSimilarity * 0.7) + (entitySimilarity * 0.3)
    }
    
    private func analyzeSearchQuery(_ query: String) async throws -> QueryAnalysis {
        // Simple query analysis - could be enhanced with more sophisticated NLP
        let words = query.lowercased().components(separatedBy: .whitespacesAndNewlines)
        
        let questionWords = ["what", "how", "when", "where", "why", "who"]
        let isQuestion = questionWords.contains { words.contains($0) }
        
        let actionWords = ["find", "search", "show", "get", "list"]
        let isAction = actionWords.contains { words.contains($0) }
        
        let intent: QueryIntent
        if isQuestion {
            intent = .question
        } else if isAction {
            intent = .action
        } else {
            intent = .search
        }
        
        return QueryAnalysis(
            originalQuery: query,
            keywords: await extractKeywords(from: query),
            entities: await extractEntities(from: query),
            intent: intent,
            confidence: 0.7
        )
    }
    
    private func calculateContextualRelevance(queryAnalysis: QueryAnalysis, indexEntry: SearchIndexEntry) -> Double {
        var relevance = 0.0
        
        // Keyword matching
        let matchingKeywords = Set(queryAnalysis.keywords).intersection(Set(indexEntry.keywords))
        if !queryAnalysis.keywords.isEmpty {
            relevance += Double(matchingKeywords.count) / Double(queryAnalysis.keywords.count) * 0.6
        }
        
        // Entity matching
        let queryEntityTexts = Set(queryAnalysis.entities.map { $0.text.lowercased() })
        let matchingEntities = queryEntityTexts.intersection(Set(indexEntry.entities.map { $0.lowercased() }))
        if !queryEntityTexts.isEmpty {
            relevance += Double(matchingEntities.count) / Double(queryEntityTexts.count) * 0.4
        }
        
        return relevance
    }
    
    private func createAISearchResult(from node: ContentNode, query: String, searchType: AISearchResultType) -> AISearchResult? {
        guard let id = node.id else { return nil }
        
        return AISearchResult(
            contentId: id,
            title: node.title ?? "Untitled",
            preview: generatePreview(node.contentText ?? "", query: query),
            contentType: ContentType(rawValue: node.contentType ?? "") ?? .text,
            relevanceScore: calculateRelevanceScore(node, query: query),
            searchType: searchType,
            highlights: generateHighlights(node.contentText ?? "", query: query),
            createdAt: node.createdAt ?? Date(),
            sourceApp: node.sourceApp ?? "unknown"
        )
    }
    
    private func createAISearchResultFromIndex(contentId: UUID, query: String, score: Double, type: AISearchResultType) async -> AISearchResult? {
        guard let indexEntry = searchIndex[contentId] else { return nil }
        
        return AISearchResult(
            contentId: contentId,
            title: indexEntry.title,
            preview: generatePreview(indexEntry.contentText, query: query),
            contentType: indexEntry.contentType,
            relevanceScore: score,
            searchType: type,
            highlights: generateHighlights(indexEntry.contentText, query: query),
            createdAt: indexEntry.createdAt,
            sourceApp: "indexed"
        )
    }
    
    private func generatePreview(_ text: String, query: String) -> String {
        let maxLength = 200
        
        if text.count <= maxLength {
            return text
        }
        
        // Try to find query context
        let queryRange = text.range(of: query, options: .caseInsensitive)
        if let range = queryRange {
            let contextStart = max(text.startIndex, text.index(range.lowerBound, offsetBy: -50, limitedBy: text.startIndex) ?? text.startIndex)
            let contextEnd = min(text.endIndex, text.index(range.upperBound, offsetBy: 50, limitedBy: text.endIndex) ?? text.endIndex)
            return String(text[contextStart..<contextEnd])
        }
        
        // Return beginning of text
        return String(text.prefix(maxLength))
    }
    
    private func generateHighlights(_ text: String, query: String) -> [SearchHighlight] {
        var highlights: [SearchHighlight] = []
        let queryWords = query.lowercased().components(separatedBy: .whitespacesAndNewlines)
        
        for word in queryWords {
            let ranges = text.ranges(of: word, options: .caseInsensitive)
            for range in ranges {
                let location = text.distance(from: text.startIndex, to: range.lowerBound)
                highlights.append(SearchHighlight(
                    range: NSRange(location: location, length: word.count),
                    type: .keyword,
                    confidence: 0.8
                ))
            }
        }
        
        return highlights
    }
    
    private func calculateRelevanceScore(_ node: ContentNode, query: String) -> Double {
        var score = 0.0
        let text = (node.contentText ?? "").lowercased()
        let queryLower = query.lowercased()
        
        // Exact match boost
        if text.contains(queryLower) {
            score += 0.5
        }
        
        // Title match boost
        if let title = node.title?.lowercased(), title.contains(queryLower) {
            score += 0.3
        }
        
        // OCR text match
        if let ocrText = node.ocrText?.lowercased(), ocrText.contains(queryLower) {
            score += 0.2
        }
        
        return min(score, 1.0)
    }
    
    private func removeDuplicateResults(_ results: [AIAISearchResult]) -> [AIAISearchResult] {
        var seen = Set<UUID>()
        return results.filter { result in
            if seen.contains(result.contentId) {
                return false
            }
            seen.insert(result.contentId)
            return true
        }
    }
    
    private func rankAISearchResults(_ results: [AIAISearchResult], query: String) -> [AIAISearchResult] {
        return results.sorted { result1, result2 in
            // Primary sort: relevance score
            if result1.relevanceScore != result2.relevanceScore {
                return result1.relevanceScore > result2.relevanceScore
            }
            
            // Secondary sort: search type priority
            let typePriority = { (type: AISearchResultType) -> Int in
                switch type {
                case .textMatch: return 4
                case .semantic: return 3
                case .tagMatch: return 2
                case .contextual: return 1
                }
            }
            
            return typePriority(result1.searchType) > typePriority(result2.searchType)
        }
    }
    
    private func addToRecentSearches(_ query: String) {
        recentSearches.removeAll { $0 == query }
        recentSearches.insert(query, at: 0)
        if recentSearches.count > 20 {
            recentSearches.removeLast()
        }
    }
    
    private func generateContentSuggestions(_ query: String) -> [AISearchSuggestion] {
        // Generate suggestions based on indexed content
        let queryLower = query.lowercased()
        var suggestions: [AISearchSuggestion] = []
        
        for (_, indexEntry) in searchIndex {
            // Title suggestions
            if indexEntry.title.lowercased().contains(queryLower) {
                suggestions.append(AISearchSuggestion(
                    text: indexEntry.title,
                    type: .content,
                    confidence: 0.7
                ))
            }
            
            // Keyword suggestions
            for keyword in indexEntry.keywords {
                if keyword.contains(queryLower) && keyword != queryLower {
                    suggestions.append(AISearchSuggestion(
                        text: keyword,
                        type: .keyword,
                        confidence: 0.6
                    ))
                }
            }
        }
        
        return Array(Set(suggestions)).prefix(5).map { $0 }
    }
    
    private func generateSmartCompletions(_ query: String) -> [AISearchSuggestion] {
        let commonCompletions = [
            "how to",
            "what is",
            "where is",
            "when did",
            "why does"
        ]
        
        return commonCompletions
            .filter { $0.hasPrefix(query.lowercased()) }
            .map { AISearchSuggestion(text: $0, type: .completion, confidence: 0.5) }
    }
    
    private func extractTagsFromNode(_ node: ContentNode) -> [String] {
        var tags: [String] = []
        
        if let contentType = node.contentType {
            tags.append(contentType)
        }
        
        if let sourceApp = node.sourceApp {
            tags.append(sourceApp)
        }
        
        return tags
    }
    
    private func isStopWord(_ word: String) -> Bool {
        let stopWords = Set(["the", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by"])
        return stopWords.contains(word.lowercased())
    }
    
    private func searchWithAdvancedCriteria(_ query: AdvancedSearchQuery) async -> [AIAISearchResult] {
        // Implementation for advanced search with complex criteria
        // This would include date ranges, multiple content types, tag combinations, etc.
        return []
    }
}

// MARK: - Supporting Data Models

struct AIAISearchResult: Identifiable, Codable {
    let id = UUID()
    let contentId: UUID
    let title: String
    let preview: String
    let contentType: ContentType
    let relevanceScore: Double
    let searchType: AISearchResultType
    let highlights: [SearchHighlight]
    let createdAt: Date
    let sourceApp: String
}

enum AISearchResultType: String, CaseIterable, Codable {
    case textMatch = "text"
    case semantic = "semantic"
    case tagMatch = "tag"
    case contextual = "contextual"
}

struct SearchHighlight: Codable {
    let range: NSRange
    let type: HighlightType
    let confidence: Double
}

enum HighlightType: String, Codable {
    case keyword = "keyword"
    case entity = "entity"
    case tag = "tag"
}

struct AIAISearchSuggestion: Identifiable, Hashable, Codable {
    let id = UUID()
    let text: String
    let type: SuggestionType
    let confidence: Double
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(text)
        hasher.combine(type)
    }
    
    static func == (lhs: AISearchSuggestion, rhs: AISearchSuggestion) -> Bool {
        return lhs.text == rhs.text && lhs.type == rhs.type
    }
}

enum SuggestionType: String, CaseIterable, Codable {
    case recent = "recent"
    case tag = "tag"
    case content = "content"
    case keyword = "keyword"
    case completion = "completion"
}

struct SearchFilters: Codable {
    let contentTypes: Set<ContentType>?
    let dateRange: ClosedRange<Date>?
    let tags: [String]?
    let minimumRelevanceScore: Double
    
    init(contentTypes: Set<ContentType>? = nil, dateRange: ClosedRange<Date>? = nil, tags: [String]? = nil, minimumRelevanceScore: Double = 0.0) {
        self.contentTypes = contentTypes
        self.dateRange = dateRange
        self.tags = tags
        self.minimumRelevanceScore = minimumRelevanceScore
    }
}

struct SearchIndexEntry {
    let contentId: UUID
    let title: String
    let contentText: String
    let ocrText: String
    let contentType: ContentType
    let keywords: [String]
    let entities: [String]
    let tags: [String]
    let createdAt: Date
    let lastUpdated: Date
}

struct QueryAnalysis {
    let originalQuery: String
    let keywords: [String]
    let entities: [NamedEntity]
    let intent: QueryIntent
    let confidence: Double
}

enum QueryIntent: String, CaseIterable, Codable {
    case search = "search"
    case question = "question"
    case action = "action"
}

struct AdvancedSearchQuery: Codable {
    let query: String
    let filters: SearchFilters
    let sortBy: SearchSortOption
    let includeArchived: Bool
}

enum SearchSortOption: String, CaseIterable, Codable {
    case relevance = "relevance"
    case dateCreated = "created"
    case dateModified = "modified"
    case title = "title"
}

// Extension to help with string range finding
extension String {
    func ranges(of substring: String, options: CompareOptions = [], locale: Locale? = nil) -> [Range<Index>] {
        var ranges: [Range<Index>] = []
        var searchStartIndex = startIndex
        
        while searchStartIndex < endIndex,
              let range = self.range(of: substring, options: options, range: searchStartIndex..<endIndex, locale: locale) {
            ranges.append(range)
            searchStartIndex = range.upperBound
        }
        
        return ranges
    }
}