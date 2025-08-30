//
//  SearchService.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import Foundation
import CoreData
import NaturalLanguage
import CoreML

// MARK: - Search Protocol

protocol SearchServiceProtocol {
    func searchContent(query: String, type: SearchType) async throws -> [SearchResult]
    func getSuggestions(for query: String) async -> [SearchSuggestion]
    func indexContent(_ content: ContentNode) async throws
    func removeFromIndex(_ contentId: UUID) async
}

// MARK: - Search Types

enum SearchType {
    case fullText
    case semantic
    case hybrid
    case fuzzy
    case exact
}

// MARK: - Search Results

struct SearchResult: Identifiable, Equatable {
    let id = UUID()
    let contentId: UUID
    let title: String
    let preview: String
    let matchType: MatchType
    let relevanceScore: Double
    let highlights: [TextHighlight]
    let semanticSimilarity: Double?
    
    enum MatchType {
        case exactMatch
        case fuzzyMatch
        case semanticMatch
        case hybridMatch
    }
}

struct TextHighlight {
    let range: NSRange
    let matchedText: String
    let confidence: Double
}

struct SearchSuggestion {
    let id = UUID()
    let text: String
    let type: SuggestionType
    let frequency: Int
    
    enum SuggestionType {
        case recentQuery
        case popularContent
        case semanticSimilar
        case autoComplete
    }
}

// MARK: - Advanced Search Service

@MainActor
class AdvancedSearchService: ObservableObject, SearchServiceProtocol {
    
    static let shared = AdvancedSearchService()
    
    // MARK: - Properties
    @Published var isIndexing: Bool = false
    @Published var indexProgress: Double = 0.0
    @Published var searchHistory: [String] = []
    
    // Search indices
    private var fullTextIndex: [String: Set<UUID>] = [:]
    private var semanticIndex: [UUID: [Float]] = [:]
    private var metadataIndex: [String: Set<UUID>] = [:]
    private var tagIndex: [String: Set<UUID>] = [:]
    
    // Search configuration
    private let maxSearchResults = 100
    private let semanticThreshold = 0.3
    private let fuzzyThreshold = 0.7
    
    // Natural Language processing
    private let tokenizer = NLTokenizer(unit: .word)
    private let lemmatizer = NLTagger(tagSchemes: [.lemma])
    private let languageRecognizer = NLLanguageRecognizer()
    
    // Core Data context
    private let persistenceController = PersistenceController.shared
    private var context: NSManagedObjectContext {
        persistenceController.container.viewContext
    }
    
    private init() {
        setupNLProcessing()
        loadSearchIndex()
    }
    
    // MARK: - Search Implementation
    
    func searchContent(query: String, type: SearchType = .hybrid) async throws -> [SearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        // Add to search history
        addToSearchHistory(query)
        
        let normalizedQuery = normalizeQuery(query)
        var results: [SearchResult] = []
        
        switch type {
        case .fullText:
            results = await performFullTextSearch(normalizedQuery)
        case .semantic:
            results = await performSemanticSearch(normalizedQuery)
        case .hybrid:
            results = await performHybridSearch(normalizedQuery)
        case .fuzzy:
            results = await performFuzzySearch(normalizedQuery)
        case .exact:
            results = await performExactSearch(normalizedQuery)
        }
        
        // Sort by relevance score
        results.sort { $0.relevanceScore > $1.relevanceScore }
        
        // Limit results
        return Array(results.prefix(maxSearchResults))
    }
    
    func getSuggestions(for query: String) async -> [SearchSuggestion] {
        var suggestions: [SearchSuggestion] = []
        
        // Recent queries
        let recentMatches = searchHistory.filter { $0.localizedCaseInsensitiveContains(query) }
        suggestions.append(contentsOf: recentMatches.map {
            SearchSuggestion(text: $0, type: .recentQuery, frequency: 1)
        })
        
        // Auto-complete from content
        suggestions.append(contentsOf: await getAutoCompleteSuggestions(query))
        
        // Popular content suggestions
        suggestions.append(contentsOf: await getPopularContentSuggestions(query))
        
        return Array(suggestions.prefix(10))
    }
    
    // MARK: - Indexing
    
    func indexContent(_ content: ContentNode) async throws {
        guard let contentId = content.id else { return }
        
        await withTaskGroup(of: Void.self) { group in
            // Full-text indexing
            group.addTask {
                await self.indexFullText(content, id: contentId)
            }
            
            // Semantic indexing
            group.addTask {
                await self.indexSemantic(content, id: contentId)
            }
            
            // Metadata indexing
            group.addTask {
                await self.indexMetadata(content, id: contentId)
            }
            
            // Tag indexing
            group.addTask {
                await self.indexTags(content, id: contentId)
            }
        }
    }
    
    func removeFromIndex(_ contentId: UUID) async {
        // Remove from all indices
        removeFromFullTextIndex(contentId)
        removeFromSemanticIndex(contentId)
        removeFromMetadataIndex(contentId)
        removeFromTagIndex(contentId)
    }
    
    // MARK: - Full-Text Search
    
    private func performFullTextSearch(_ query: String) async -> [SearchResult] {
        let queryTerms = extractKeywords(query)
        var results: [SearchResult] = []
        var scoreMap: [UUID: Double] = [:]
        
        for term in queryTerms {
            if let contentIds = fullTextIndex[term.lowercased()] {
                for contentId in contentIds {
                    scoreMap[contentId, default: 0] += calculateTermScore(term, in: contentId)
                }
            }
        }
        
        // Convert scores to results
        for (contentId, score) in scoreMap {
            if let content = await getContent(by: contentId) {
                let highlights = findHighlights(query: query, in: content)
                let result = SearchResult(
                    contentId: contentId,
                    title: content.title ?? "Untitled",
                    preview: createPreview(from: content, highlights: highlights),
                    matchType: .exactMatch,
                    relevanceScore: score,
                    highlights: highlights,
                    semanticSimilarity: nil
                )
                results.append(result)
            }
        }
        
        return results
    }
    
    // MARK: - Semantic Search
    
    private func performSemanticSearch(_ query: String) async -> [SearchResult] {
        guard let queryEmbedding = await generateEmbedding(for: query) else {
            return []
        }
        
        var results: [SearchResult] = []
        
        for (contentId, embedding) in semanticIndex {
            let similarity = cosineSimilarity(queryEmbedding, embedding)
            
            if similarity > semanticThreshold {
                if let content = await getContent(by: contentId) {
                    let result = SearchResult(
                        contentId: contentId,
                        title: content.title ?? "Untitled",
                        preview: content.contentText?.prefix(200).description ?? "",
                        matchType: .semanticMatch,
                        relevanceScore: Double(similarity),
                        highlights: [],
                        semanticSimilarity: Double(similarity)
                    )
                    results.append(result)
                }
            }
        }
        
        return results
    }
    
    // MARK: - Hybrid Search
    
    private func performHybridSearch(_ query: String) async -> [SearchResult] {
        let fullTextResults = await performFullTextSearch(query)
        let semanticResults = await performSemanticSearch(query)
        
        // Merge and re-rank results
        var mergedResults: [UUID: SearchResult] = [:]
        
        // Add full-text results
        for result in fullTextResults {
            mergedResults[result.contentId] = result
        }
        
        // Merge semantic results
        for semanticResult in semanticResults {
            if let existing = mergedResults[semanticResult.contentId] {
                // Combine scores
                let combinedScore = (existing.relevanceScore * 0.6) + (semanticResult.relevanceScore * 0.4)
                mergedResults[semanticResult.contentId] = SearchResult(
                    contentId: existing.contentId,
                    title: existing.title,
                    preview: existing.preview,
                    matchType: .hybridMatch,
                    relevanceScore: combinedScore,
                    highlights: existing.highlights,
                    semanticSimilarity: semanticResult.semanticSimilarity
                )
            } else {
                mergedResults[semanticResult.contentId] = semanticResult
            }
        }
        
        return Array(mergedResults.values)
    }
    
    // MARK: - Fuzzy Search
    
    private func performFuzzySearch(_ query: String) async -> [SearchResult] {
        var results: [SearchResult] = []
        let queryTerms = extractKeywords(query)
        
        // Search with edit distance
        for (term, contentIds) in fullTextIndex {
            for queryTerm in queryTerms {
                let similarity = levenshteinSimilarity(queryTerm.lowercased(), term)
                if similarity > fuzzyThreshold {
                    for contentId in contentIds {
                        if let content = await getContent(by: contentId) {
                            let result = SearchResult(
                                contentId: contentId,
                                title: content.title ?? "Untitled",
                                preview: content.contentText?.prefix(200).description ?? "",
                                matchType: .fuzzyMatch,
                                relevanceScore: Double(similarity),
                                highlights: [],
                                semanticSimilarity: nil
                            )
                            results.append(result)
                        }
                    }
                }
            }
        }
        
        return results
    }
    
    // MARK: - Exact Search
    
    private func performExactSearch(_ query: String) async -> [SearchResult] {
        let exactQuery = query.lowercased()
        var results: [SearchResult] = []
        
        if let contentIds = fullTextIndex[exactQuery] {
            for contentId in contentIds {
                if let content = await getContent(by: contentId) {
                    let highlights = findExactHighlights(query: query, in: content)
                    let result = SearchResult(
                        contentId: contentId,
                        title: content.title ?? "Untitled",
                        preview: createPreview(from: content, highlights: highlights),
                        matchType: .exactMatch,
                        relevanceScore: 1.0,
                        highlights: highlights,
                        semanticSimilarity: nil
                    )
                    results.append(result)
                }
            }
        }
        
        return results
    }
    
    // MARK: - Helper Methods
    
    private func setupNLProcessing() {
        tokenizer.string = ""
        lemmatizer.string = ""
    }
    
    private func normalizeQuery(_ query: String) -> String {
        return query.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
    
    private func extractKeywords(_ text: String) -> [String] {
        tokenizer.string = text
        var keywords: [String] = []
        
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
            let token = String(text[tokenRange])
            if token.count > 2 && !isStopWord(token) {
                keywords.append(token.lowercased())
            }
            return true
        }
        
        return keywords
    }
    
    private func isStopWord(_ word: String) -> Bool {
        let stopWords: Set<String> = ["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by", "is", "are", "was", "were", "be", "been", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should"]
        return stopWords.contains(word.lowercased())
    }
    
    private func calculateTermScore(_ term: String, in contentId: UUID) -> Double {
        // TF-IDF calculation would go here
        // For now, return a simple frequency score
        return 1.0
    }
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0 }
        
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let normA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let normB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        
        return dotProduct / (normA * normB)
    }
    
    private func levenshteinSimilarity(_ s1: String, _ s2: String) -> Float {
        let distance = levenshteinDistance(s1, s2)
        let maxLength = max(s1.count, s2.count)
        return maxLength > 0 ? Float(maxLength - distance) / Float(maxLength) : 0
    }
    
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1)
        let b = Array(s2)
        
        var distances = Array(0...b.count)
        
        for i in 1...a.count {
            var newDistances = [i]
            
            for j in 1...b.count {
                let deletionDistance = distances[j] + 1
                let insertionDistance = newDistances[j-1] + 1
                let substitutionDistance = distances[j-1] + (a[i-1] == b[j-1] ? 0 : 1)
                
                newDistances.append(min(deletionDistance, insertionDistance, substitutionDistance))
            }
            
            distances = newDistances
        }
        
        return distances[b.count]
    }
    
    private func addToSearchHistory(_ query: String) {
        searchHistory.removeAll { $0 == query }
        searchHistory.insert(query, at: 0)
        searchHistory = Array(searchHistory.prefix(50)) // Keep last 50 searches
    }
    
    // MARK: - Async Helper Methods
    
    private func getContent(by id: UUID) async -> ContentNode? {
        return await withCheckedContinuation { continuation in
            context.perform {
                let request: NSFetchRequest<ContentNode> = ContentNode.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                request.fetchLimit = 1
                
                do {
                    let results = try self.context.fetch(request)
                    continuation.resume(returning: results.first)
                } catch {
                    print("Error fetching content: \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    private func generateEmbedding(for text: String) async -> [Float]? {
        // In a real implementation, this would use a machine learning model
        // For now, return a simple hash-based embedding
        let hash = text.hash
        return [Float(hash % 1000) / 1000.0, Float((hash >> 8) % 1000) / 1000.0]
    }
    
    private func findHighlights(query: String, in content: ContentNode) -> [TextHighlight] {
        // Implementation for finding and highlighting matching text
        return []
    }
    
    private func findExactHighlights(query: String, in content: ContentNode) -> [TextHighlight] {
        // Implementation for exact match highlighting
        return []
    }
    
    private func createPreview(from content: ContentNode, highlights: [TextHighlight]) -> String {
        return content.contentText?.prefix(200).description ?? ""
    }
    
    private func getAutoCompleteSuggestions(_ query: String) async -> [SearchSuggestion] {
        // Implementation for auto-complete suggestions
        return []
    }
    
    private func getPopularContentSuggestions(_ query: String) async -> [SearchSuggestion] {
        // Implementation for popular content suggestions
        return []
    }
    
    // MARK: - Indexing Helper Methods
    
    private func indexFullText(_ content: ContentNode, id: UUID) async {
        guard let text = content.contentText else { return }
        let keywords = extractKeywords(text)
        
        for keyword in keywords {
            fullTextIndex[keyword, default: Set<UUID>()].insert(id)
        }
    }
    
    private func indexSemantic(_ content: ContentNode, id: UUID) async {
        guard let text = content.contentText,
              let embedding = await generateEmbedding(for: text) else { return }
        
        semanticIndex[id] = embedding
    }
    
    private func indexMetadata(_ content: ContentNode, id: UUID) async {
        // Index metadata fields
        if let sourceApp = content.sourceApp {
            metadataIndex["source:\(sourceApp)", default: Set<UUID>()].insert(id)
        }
        
        if let contentType = content.contentType {
            metadataIndex["type:\(contentType)", default: Set<UUID>()].insert(id)
        }
    }
    
    private func indexTags(_ content: ContentNode, id: UUID) async {
        // Index tags when tag relationship is implemented
        // For now, this is a placeholder
    }
    
    private func removeFromFullTextIndex(_ contentId: UUID) {
        for (term, var contentIds) in fullTextIndex {
            contentIds.remove(contentId)
            if contentIds.isEmpty {
                fullTextIndex.removeValue(forKey: term)
            } else {
                fullTextIndex[term] = contentIds
            }
        }
    }
    
    private func removeFromSemanticIndex(_ contentId: UUID) {
        semanticIndex.removeValue(forKey: contentId)
    }
    
    private func removeFromMetadataIndex(_ contentId: UUID) {
        for (key, var contentIds) in metadataIndex {
            contentIds.remove(contentId)
            if contentIds.isEmpty {
                metadataIndex.removeValue(forKey: key)
            } else {
                metadataIndex[key] = contentIds
            }
        }
    }
    
    private func removeFromTagIndex(_ contentId: UUID) {
        for (tag, var contentIds) in tagIndex {
            contentIds.remove(contentId)
            if contentIds.isEmpty {
                tagIndex.removeValue(forKey: tag)
            } else {
                tagIndex[tag] = contentIds
            }
        }
    }
    
    private func loadSearchIndex() {
        // Load existing index from persistence if needed
        print("🔍 Search index loaded")
    }
    
    private func saveSearchIndex() {
        // Save index to persistence if needed
        print("💾 Search index saved")
    }
}

// MARK: - Search Extensions

extension AdvancedSearchService {
    
    /// Rebuild the entire search index
    func rebuildIndex() async {
        isIndexing = true
        indexProgress = 0.0
        
        // Clear existing indices
        fullTextIndex.removeAll()
        semanticIndex.removeAll()
        metadataIndex.removeAll()
        tagIndex.removeAll()
        
        // Fetch all content
        let request: NSFetchRequest<ContentNode> = ContentNode.fetchRequest()
        
        do {
            let allContent = try context.fetch(request)
            let totalCount = allContent.count
            
            for (index, content) in allContent.enumerated() {
                try await indexContent(content)
                indexProgress = Double(index + 1) / Double(totalCount)
            }
            
            saveSearchIndex()
            
        } catch {
            print("Error rebuilding search index: \(error)")
        }
        
        isIndexing = false
        indexProgress = 1.0
    }
}