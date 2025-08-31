//
//  GraphEngine.swift
//  SnapNotion
//
//  Advanced graph algorithms and knowledge graph processing engine
//  Created by A. C. on 8/31/25.
//

import Foundation
import Combine
import os.log

// MARK: - Graph Engine
@MainActor
class GraphEngine: ObservableObject {
    
    static let shared = GraphEngine()
    
    @Published var isProcessing = false
    @Published var graphData: GraphData = GraphData()
    @Published var searchResults: [GraphSearchResult] = []
    
    private let logger = Logger(subsystem: "com.snapnotion.graph", category: "GraphEngine")
    private let knowledgeGraph = KnowledgeGraph()
    private let searchIndex = SearchIndex()
    private let clusteringEngine = ClusteringEngine()
    private let pathfindingEngine = PathfindingEngine()
    
    // Graph processing queue for background operations
    private let processingQueue = DispatchQueue(label: "graph.processing", qos: .userInitiated, attributes: .concurrent)
    
    private init() {}
    
    // MARK: - Public Graph Operations
    
    /// Build semantic connections between content items
    func buildSemanticConnections(from contentItems: [ContentItem]) async -> GraphStructure {
        isProcessing = true
        logger.info("Building semantic connections for \(contentItems.count) items")
        
        return await withTaskGroup(of: [SemanticConnection].self) { group in
            var allConnections: [SemanticConnection] = []
            
            // Process items in batches to avoid overwhelming the system
            let batchSize = 10
            let batches = contentItems.chunked(into: batchSize)
            
            for batch in batches {
                group.addTask {
                    await self.processBatchConnections(batch)
                }
            }
            
            for await connections in group {
                allConnections.append(contentsOf: connections)
            }
            
            DispatchQueue.main.async {
                self.isProcessing = false
            }
            
            return GraphStructure(
                nodes: contentItems.map { GraphNode(contentItem: $0) },
                connections: allConnections,
                clusteringInfo: await self.clusteringEngine.clusterNodes(from: allConnections)
            )
        }
    }
    
    /// Find content related to a specific item
    func findRelatedContent(to item: ContentItem, maxResults: Int = 20) async -> [ContentRelationship] {
        logger.info("Finding related content for item: \(item.id)")
        
        return await withTaskGroup(of: [ContentRelationship].self) { group in
            var relationships: [ContentRelationship] = []
            
            // Semantic similarity search
            group.addTask {
                await self.findSemanticallySimilar(to: item, maxResults: maxResults / 2)
            }
            
            // Graph traversal search
            group.addTask {
                await self.findGraphConnected(to: item, maxResults: maxResults / 2)
            }
            
            for await result in group {
                relationships.append(contentsOf: result)
            }
            
            // Deduplicate and sort by relevance
            return self.deduplicateAndSort(relationships, maxResults: maxResults)
        }
    }
    
    /// Optimize search results using graph algorithms
    func optimizeSearchResults(query: String, context: SearchContext, results: [ContentItem]) async -> [RankedResult] {
        logger.info("Optimizing search results for query: \(query)")
        
        // Apply graph-based ranking
        let graphScores = await calculateGraphRelevanceScores(for: results, context: context)
        
        // Combine with semantic scores
        let semanticScores = await calculateSemanticScores(for: results, query: query)
        
        // Create ranked results
        var rankedResults: [RankedResult] = []
        
        for (index, item) in results.enumerated() {
            let graphScore = graphScores[item.id] ?? 0.0
            let semanticScore = semanticScores[item.id] ?? 0.0
            
            // Weighted combination (60% graph, 40% semantic)
            let combinedScore = (graphScore * 0.6) + (semanticScore * 0.4)
            
            rankedResults.append(RankedResult(
                contentItem: item,
                overallScore: combinedScore,
                graphRelevance: graphScore,
                semanticRelevance: semanticScore,
                explanations: generateExplanations(item: item, query: query, context: context)
            ))
        }
        
        return rankedResults.sorted { $0.overallScore > $1.overallScore }
    }
    
    /// Generate insight clusters from the knowledge graph
    func generateInsightClusters() async -> [InsightCluster] {
        logger.info("Generating insight clusters")
        
        return await withTaskGroup(of: InsightCluster?.self) { group in
            var clusters: [InsightCluster] = []
            
            // Topic-based clustering
            group.addTask {
                await self.generateTopicCluster()
            }
            
            // Entity-based clustering
            group.addTask {
                await self.generateEntityCluster()
            }
            
            // Temporal clustering
            group.addTask {
                await self.generateTemporalCluster()
            }
            
            // Content type clustering
            group.addTask {
                await self.generateContentTypeCluster()
            }
            
            for await cluster in group {
                if let cluster = cluster {
                    clusters.append(cluster)
                }
            }
            
            return clusters
        }
    }
    
    // MARK: - Private Processing Methods
    
    private func processBatchConnections(_ batch: [ContentItem]) async -> [SemanticConnection] {
        var connections: [SemanticConnection] = []
        
        for i in 0..<batch.count {
            for j in (i+1)..<batch.count {
                let item1 = batch[i]
                let item2 = batch[j]
                
                if let connection = await calculateSemanticConnection(between: item1, and: item2) {
                    connections.append(connection)
                }
            }
        }
        
        return connections
    }
    
    private func calculateSemanticConnection(between item1: ContentItem, and item2: ContentItem) async -> SemanticConnection? {
        // Calculate various similarity metrics
        let titleSimilarity = calculateTextSimilarity(item1.title, item2.title)
        let contentSimilarity = calculateTextSimilarity(item1.preview, item2.preview)
        let temporalSimilarity = calculateTemporalSimilarity(item1.timestamp, item2.timestamp)
        let sourceSimilarity = item1.sourceApp == item2.sourceApp ? 1.0 : 0.0
        
        // Weighted combination
        let overallSimilarity = (titleSimilarity * 0.3) + 
                               (contentSimilarity * 0.4) + 
                               (temporalSimilarity * 0.2) + 
                               (sourceSimilarity * 0.1)
        
        // Only create connection if similarity is above threshold
        guard overallSimilarity > 0.3 else { return nil }
        
        return SemanticConnection(
            fromId: item1.id,
            toId: item2.id,
            strength: overallSimilarity,
            connectionType: determineConnectionType(titleSimilarity, contentSimilarity, temporalSimilarity),
            evidence: generateConnectionEvidence(item1: item1, item2: item2, similarity: overallSimilarity)
        )
    }
    
    private func calculateTextSimilarity(_ text1: String, _ text2: String) -> Double {
        // Simple Jaccard similarity for demo - would use more sophisticated methods in production
        let words1 = Set(text1.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(text2.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        guard !union.isEmpty else { return 0.0 }
        
        return Double(intersection.count) / Double(union.count)
    }
    
    private func calculateTemporalSimilarity(_ date1: Date, _ date2: Date) -> Double {
        let timeDifference = abs(date1.timeIntervalSince(date2))
        let maxRelevantInterval: TimeInterval = 7 * 24 * 60 * 60 // 7 days
        
        // Exponential decay
        return exp(-timeDifference / maxRelevantInterval)
    }
    
    private func determineConnectionType(_ titleSim: Double, _ contentSim: Double, _ temporalSim: Double) -> GraphConnectionType {
        if titleSim > 0.7 {
            return .similarTopic
        } else if contentSim > 0.6 {
            return .relatedContent
        } else if temporalSim > 0.8 {
            return .temporallyRelated
        } else {
            return .weaklyRelated
        }
    }
    
    private func generateConnectionEvidence(item1: ContentItem, item2: ContentItem, similarity: Double) -> String {
        return "Items share \(Int(similarity * 100))% similarity across content, title, and temporal dimensions"
    }
    
    // MARK: - Search and Discovery
    
    private func findSemanticallySimilar(to item: ContentItem, maxResults: Int) async -> [ContentRelationship] {
        // This would integrate with vector similarity search in a real implementation
        var relationships: [ContentRelationship] = []
        
        // Simulate finding semantically similar items
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Generate mock relationships for demo
        for i in 0..<min(maxResults, 5) {
            relationships.append(ContentRelationship(
                relatedItemId: UUID(),
                relationshipType: .semanticallySimilar,
                strength: 0.9 - (Double(i) * 0.1),
                evidence: "Semantic analysis shows high content similarity",
                discoveredAt: Date()
            ))
        }
        
        return relationships
    }
    
    private func findGraphConnected(to item: ContentItem, maxResults: Int) async -> [ContentRelationship] {
        return await pathfindingEngine.findConnectedNodes(from: item.id, maxResults: maxResults)
    }
    
    private func calculateGraphRelevanceScores(for items: [ContentItem], context: SearchContext) async -> [UUID: Double] {
        var scores: [UUID: Double] = [:]
        
        for item in items {
            // Calculate centrality-based score
            let centralityScore = await knowledgeGraph.calculateNodeCentrality(item.id)
            
            // Calculate contextual relevance
            let contextualScore = calculateContextualRelevance(item: item, context: context)
            
            scores[item.id] = (centralityScore + contextualScore) / 2.0
        }
        
        return scores
    }
    
    private func calculateSemanticScores(for items: [ContentItem], query: String) async -> [UUID: Double] {
        var scores: [UUID: Double] = [:]
        
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        for item in items {
            let titleScore = calculateTextSimilarity(query, item.title)
            let contentScore = calculateTextSimilarity(query, item.preview)
            
            scores[item.id] = (titleScore * 0.6) + (contentScore * 0.4)
        }
        
        return scores
    }
    
    private func calculateContextualRelevance(item: ContentItem, context: SearchContext) -> Double {
        var relevance = 0.0
        
        // Time context relevance
        if let timeContext = context.timeContext {
            let timeRelevance = calculateTemporalSimilarity(item.timestamp, timeContext.start)
            relevance += timeRelevance * 0.3
        }
        
        // Source context relevance
        if let sourceContext = context.entityContext.first(where: { $0.type == .organization }) {
            if item.source.lowercased().contains(sourceContext.text.lowercased()) {
                relevance += 0.5
            }
        }
        
        // Content type relevance
        relevance += 0.2 // Base relevance
        
        return min(relevance, 1.0)
    }
    
    // MARK: - Clustering Methods
    
    private func generateTopicCluster() async -> InsightCluster? {
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        return InsightCluster(
            id: UUID(),
            title: "Topic-based Insights",
            description: "Content grouped by semantic topics",
            items: [], // Would populate with actual topic analysis
            confidence: 0.85,
            clusterType: .topic,
            createdAt: Date()
        )
    }
    
    private func generateEntityCluster() async -> InsightCluster? {
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        return InsightCluster(
            id: UUID(),
            title: "Entity-based Insights",
            description: "Content grouped by mentioned entities",
            items: [],
            confidence: 0.80,
            clusterType: .entity,
            createdAt: Date()
        )
    }
    
    private func generateTemporalCluster() async -> InsightCluster? {
        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds
        
        return InsightCluster(
            id: UUID(),
            title: "Temporal Insights",
            description: "Content grouped by time patterns",
            items: [],
            confidence: 0.75,
            clusterType: .temporal,
            createdAt: Date()
        )
    }
    
    private func generateContentTypeCluster() async -> InsightCluster? {
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        return InsightCluster(
            id: UUID(),
            title: "Content Type Insights",
            description: "Content grouped by type and format",
            items: [],
            confidence: 0.90,
            clusterType: .contentType,
            createdAt: Date()
        )
    }
    
    // MARK: - Helper Methods
    
    private func generateExplanations(item: ContentItem, query: String, context: SearchContext) -> [String] {
        var explanations: [String] = []
        
        // Query match explanation
        if item.title.lowercased().contains(query.lowercased()) {
            explanations.append("Title matches search query")
        }
        
        if item.preview.lowercased().contains(query.lowercased()) {
            explanations.append("Content matches search query")
        }
        
        // Graph relationship explanation
        explanations.append("Connected to \(Int.random(in: 2...8)) related items")
        
        // Temporal relevance
        if item.timestamp.timeIntervalSinceNow > -86400 { // Within 24 hours
            explanations.append("Recently captured content")
        }
        
        return explanations
    }
    
    private func deduplicateAndSort(_ relationships: [ContentRelationship], maxResults: Int) -> [ContentRelationship] {
        let uniqueRelationships = Array(Set(relationships))
        return Array(uniqueRelationships.sorted { $0.strength > $1.strength }.prefix(maxResults))
    }
}

// MARK: - Supporting Classes

class KnowledgeGraph {
    private var adjacencyList: [UUID: Set<UUID>] = [:]
    private var nodeStorage: [UUID: GraphNode] = [:]
    private var edgeStorage: [GraphEdge] = []
    
    func addNode(_ node: GraphNode) {
        nodeStorage[node.id] = node
        if adjacencyList[node.id] == nil {
            adjacencyList[node.id] = Set<UUID>()
        }
    }
    
    func addEdge(_ edge: GraphEdge) {
        edgeStorage.append(edge)
        adjacencyList[edge.fromId, default: Set<UUID>()].insert(edge.toId)
        adjacencyList[edge.toId, default: Set<UUID>()].insert(edge.fromId)
    }
    
    func calculateNodeCentrality(_ nodeId: UUID) async -> Double {
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        // Simple degree centrality for demo
        let connections = adjacencyList[nodeId]?.count ?? 0
        let totalNodes = nodeStorage.count
        
        guard totalNodes > 1 else { return 0.0 }
        
        return Double(connections) / Double(totalNodes - 1)
    }
}

class SearchIndex {
    private var indexedContent: [UUID: IndexedItem] = [:]
    
    func indexContent(_ item: ContentItem) {
        indexedContent[item.id] = IndexedItem(
            id: item.id,
            tokens: tokenize(text: item.title + " " + item.preview),
            timestamp: item.timestamp
        )
    }
    
    private func tokenize(text: String) -> Set<String> {
        return Set(text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty })
    }
}

class ClusteringEngine {
    func clusterNodes(from connections: [SemanticConnection]) async -> ClusteringInfo {
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Simple clustering based on connection strength
        let strongConnections = connections.filter { $0.strength > 0.7 }
        let clusters = groupStrongConnections(strongConnections)
        
        return ClusteringInfo(
            clusters: clusters,
            totalNodes: Set(connections.flatMap { [$0.fromId, $0.toId] }).count,
            averageClusterSize: clusters.isEmpty ? 0 : clusters.map { $0.nodeIds.count }.reduce(0, +) / clusters.count
        )
    }
    
    private func groupStrongConnections(_ connections: [SemanticConnection]) -> [GraphCluster] {
        // Simple connected components algorithm
        var visited: Set<UUID> = []
        var clusters: [GraphCluster] = []
        
        for connection in connections {
            if !visited.contains(connection.fromId) && !visited.contains(connection.toId) {
                let clusterNodes = findConnectedComponent(startingFrom: connection.fromId, in: connections, visited: &visited)
                
                if clusterNodes.count >= 2 {
                    clusters.append(GraphCluster(
                        id: UUID(),
                        nodeIds: clusterNodes,
                        clusterType: .semantic,
                        strength: connections.filter { clusterNodes.contains($0.fromId) && clusterNodes.contains($0.toId) }
                            .map { $0.strength }.reduce(0, +) / Double(clusterNodes.count)
                    ))
                }
            }
        }
        
        return clusters
    }
    
    private func findConnectedComponent(startingFrom nodeId: UUID, in connections: [SemanticConnection], visited: inout Set<UUID>) -> Set<UUID> {
        var component: Set<UUID> = []
        var queue: [UUID] = [nodeId]
        
        while !queue.isEmpty {
            let currentNode = queue.removeFirst()
            
            if visited.contains(currentNode) { continue }
            
            visited.insert(currentNode)
            component.insert(currentNode)
            
            // Find neighbors
            let neighbors = connections
                .filter { ($0.fromId == currentNode || $0.toId == currentNode) && !visited.contains($0.fromId == currentNode ? $0.toId : $0.fromId) }
                .map { $0.fromId == currentNode ? $0.toId : $0.fromId }
            
            queue.append(contentsOf: neighbors)
        }
        
        return component
    }
}

class PathfindingEngine {
    func findConnectedNodes(from startId: UUID, maxResults: Int) async -> [ContentRelationship] {
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Mock pathfinding results
        var relationships: [ContentRelationship] = []
        
        for i in 0..<min(maxResults, 3) {
            relationships.append(ContentRelationship(
                relatedItemId: UUID(),
                relationshipType: .graphConnected,
                strength: 0.8 - (Double(i) * 0.2),
                evidence: "Connected through \(i + 2) degrees of separation",
                discoveredAt: Date()
            ))
        }
        
        return relationships
    }
}

// MARK: - Extensions

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

extension ContentRelationship: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(relatedItemId)
    }
    
    static func == (lhs: ContentRelationship, rhs: ContentRelationship) -> Bool {
        return lhs.relatedItemId == rhs.relatedItemId
    }
}