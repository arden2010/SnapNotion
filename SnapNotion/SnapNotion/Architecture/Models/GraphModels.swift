//
//  GraphModels.swift
//  SnapNotion
//
//  Graph algorithm models and data structures
//  Created by A. C. on 8/31/25.
//

import Foundation
import SwiftUI

// MARK: - Core Graph Models

struct GraphData {
    var nodes: [GraphNode] = []
    var connections: [GraphEdge] = []
    var clusters: [GraphCluster] = []
    var metadata: GraphMetadata = GraphMetadata()
}

struct GraphNode: Identifiable, Hashable {
    let id: UUID
    let contentId: UUID
    let title: String
    let type: NodeType
    let position: CGPoint
    let size: CGSize
    let color: Color
    let weight: Double
    let metadata: NodeMetadata
    
    init(contentItem: ContentItem) {
        self.id = contentItem.id
        self.contentId = contentItem.id
        self.title = contentItem.title
        self.type = NodeType.from(contentType: contentItem.type)
        self.position = CGPoint.zero // Will be calculated by layout algorithm
        self.size = CGSize(width: 60, height: 60)
        self.color = NodeType.from(contentType: contentItem.type).color
        self.weight = 1.0
        self.metadata = NodeMetadata(
            createdAt: contentItem.timestamp,
            source: contentItem.source,
            isFavorite: contentItem.isFavorite,
            connectionCount: 0
        )
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: GraphNode, rhs: GraphNode) -> Bool {
        return lhs.id == rhs.id
    }
}

enum NodeType: String, CaseIterable {
    case document = "document"
    case image = "image"
    case text = "text"
    case web = "web"
    case pdf = "pdf"
    case mixed = "mixed"
    case task = "task"
    case person = "person"
    case organization = "organization"
    case location = "location"
    case concept = "concept"
    
    var displayName: String {
        switch self {
        case .document: return "Document"
        case .image: return "Image"
        case .text: return "Text"
        case .web: return "Web"
        case .pdf: return "PDF"
        case .mixed: return "Mixed"
        case .task: return "Task"
        case .person: return "Person"
        case .organization: return "Organization"
        case .location: return "Location"
        case .concept: return "Concept"
        }
    }
    
    var color: Color {
        switch self {
        case .document: return .blue
        case .image: return .green
        case .text: return .purple
        case .web: return .orange
        case .pdf: return .red
        case .mixed: return .indigo
        case .task: return .pink
        case .person: return .cyan
        case .organization: return .mint
        case .location: return .brown
        case .concept: return .yellow
        }
    }
    
    var icon: String {
        switch self {
        case .document: return "doc.fill"
        case .image: return "photo.fill"
        case .text: return "text.alignleft"
        case .web: return "globe"
        case .pdf: return "doc.richtext.fill"
        case .mixed: return "doc.on.doc.fill"
        case .task: return "checkmark.circle.fill"
        case .person: return "person.fill"
        case .organization: return "building.2.fill"
        case .location: return "location.fill"
        case .concept: return "lightbulb.fill"
        }
    }
    
    static func from(contentType: ContentType) -> NodeType {
        switch contentType {
        case .text: return .text
        case .image: return .image
        case .pdf: return .pdf
        case .web: return .web
        case .mixed: return .mixed
        }
    }
}

struct NodeMetadata {
    let createdAt: Date
    let source: String
    let isFavorite: Bool
    var connectionCount: Int
    var centralityScore: Double = 0.0
    var clusterIds: [UUID] = []
    var lastAccessed: Date?
}

enum GraphConnectionType: String, CaseIterable {
    case similarTopic = "similar_topic"
    case relatedContent = "related_content"
    case temporallyRelated = "temporally_related"
    case semanticallySimilar = "semantically_similar"
    case graphConnected = "graph_connected"
    case weaklyRelated = "weakly_related"
    case mentionedTogether = "mentioned_together"
    case causalRelation = "causal_relation"
    case hierarchical = "hierarchical"
    
    var displayName: String {
        switch self {
        case .similarTopic: return "Similar Topic"
        case .relatedContent: return "Related Content"
        case .temporallyRelated: return "Time-Related"
        case .semanticallySimilar: return "Semantically Similar"
        case .graphConnected: return "Graph Connected"
        case .weaklyRelated: return "Weakly Related"
        case .mentionedTogether: return "Co-mentioned"
        case .causalRelation: return "Causal"
        case .hierarchical: return "Hierarchical"
        }
    }
    
    var color: Color {
        switch self {
        case .similarTopic: return .blue
        case .relatedContent: return .green
        case .temporallyRelated: return .orange
        case .semanticallySimilar: return .purple
        case .graphConnected: return .red
        case .weaklyRelated: return .gray
        case .mentionedTogether: return .cyan
        case .causalRelation: return .yellow
        case .hierarchical: return .indigo
        }
    }
    
    var isBidirectional: Bool {
        switch self {
        case .similarTopic, .relatedContent, .temporallyRelated, 
             .semanticallySimilar, .weaklyRelated, .mentionedTogether:
            return true
        case .graphConnected, .causalRelation, .hierarchical:
            return false
        }
    }
}

struct GraphEdge: Identifiable, Hashable {
    let id: UUID
    let fromId: UUID
    let toId: UUID
    let connectionType: GraphConnectionType
    let strength: Double
    let bidirectional: Bool
    let color: Color
    let thickness: CGFloat
    let metadata: EdgeMetadata
    
    init(from: UUID, to: UUID, type: GraphConnectionType, strength: Double, evidence: String) {
        self.id = UUID()
        self.fromId = from
        self.toId = to
        self.connectionType = type
        self.strength = strength
        self.bidirectional = type.isBidirectional
        self.color = type.color
        self.thickness = CGFloat(strength * 3.0 + 1.0) // 1-4pt thickness based on strength
        self.metadata = EdgeMetadata(
            createdAt: Date(),
            evidence: evidence,
            confidence: strength
        )
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: GraphEdge, rhs: GraphEdge) -> Bool {
        return lhs.id == rhs.id
    }
}

struct EdgeMetadata {
    let createdAt: Date
    let evidence: String
    let confidence: Double
    var strength: Double = 0.0
    var isVisible: Bool = true
    var lastUpdated: Date = Date()
}

// MARK: - Graph Structure Models

struct SemanticConnection {
    let fromId: UUID
    let toId: UUID
    let strength: Double
    let connectionType: GraphConnectionType
    let evidence: String
}

struct GraphStructure {
    let nodes: [GraphNode]
    let connections: [SemanticConnection]
    let clusteringInfo: ClusteringInfo
}

struct ClusteringInfo {
    let clusters: [GraphCluster]
    let totalNodes: Int
    let averageClusterSize: Int
}

struct GraphCluster: Identifiable {
    let id: UUID
    let nodeIds: Set<UUID>
    let clusterType: ClusterType
    let strength: Double
    let centroid: CGPoint?
    let boundingRect: CGRect?
    let color: Color
    let metadata: ClusterMetadata
    
    init(id: UUID, nodeIds: Set<UUID>, clusterType: ClusterType, strength: Double) {
        self.id = id
        self.nodeIds = nodeIds
        self.clusterType = clusterType
        self.strength = strength
        self.centroid = nil // Will be calculated by layout
        self.boundingRect = nil // Will be calculated by layout
        self.color = clusterType.color.opacity(0.2)
        self.metadata = ClusterMetadata(
            createdAt: Date(),
            nodeCount: nodeIds.count,
            averageStrength: strength
        )
    }
}

enum ClusterType: String, CaseIterable {
    case semantic = "semantic"
    case temporal = "temporal"
    case topic = "topic"
    case entity = "entity"
    case contentType = "content_type"
    case source = "source"
    
    var displayName: String {
        switch self {
        case .semantic: return "Semantic"
        case .temporal: return "Temporal"
        case .topic: return "Topic"
        case .entity: return "Entity"
        case .contentType: return "Content Type"
        case .source: return "Source"
        }
    }
    
    var color: Color {
        switch self {
        case .semantic: return .purple
        case .temporal: return .orange
        case .topic: return .blue
        case .entity: return .green
        case .contentType: return .red
        case .source: return .cyan
        }
    }
}

struct ClusterMetadata {
    let createdAt: Date
    let nodeCount: Int
    let averageStrength: Double
    var isVisible: Bool = true
    var label: String?
    var description: String?
}

struct GraphMetadata {
    var totalNodes: Int = 0
    var totalConnections: Int = 0
    var averageConnectivity: Double = 0.0
    var lastUpdated: Date = Date()
    var layoutAlgorithm: LayoutAlgorithm = .forceDirected
    var viewportBounds: CGRect = CGRect.zero
    var zoomLevel: Double = 1.0
}

enum LayoutAlgorithm: String, CaseIterable {
    case forceDirected = "force_directed"
    case hierarchical = "hierarchical"
    case circular = "circular"
    case grid = "grid"
    case cluster = "cluster"
    
    var displayName: String {
        switch self {
        case .forceDirected: return "Force-Directed"
        case .hierarchical: return "Hierarchical"
        case .circular: return "Circular"
        case .grid: return "Grid"
        case .cluster: return "Cluster-Based"
        }
    }
}

// MARK: - Search and Discovery Models

struct GraphSearchResult: Identifiable {
    let id: UUID
    let nodeId: UUID
    let relevanceScore: Double
    let pathFromQuery: [UUID]
    let explanation: String
    let highlightPath: [GraphEdge]
}

struct ContentRelationship: Identifiable {
    let id: UUID = UUID()
    let relatedItemId: UUID
    let relationshipType: RelationshipType
    let strength: Double
    let evidence: String
    let discoveredAt: Date
}

enum RelationshipType: String, CaseIterable {
    case semanticallySimilar = "semantically_similar"
    case graphConnected = "graph_connected"
    case temporallyRelated = "temporally_related"
    case topicallySimilar = "topically_similar"
    case sourceRelated = "source_related"
    
    var displayName: String {
        switch self {
        case .semanticallySimilar: return "Semantically Similar"
        case .graphConnected: return "Graph Connected"
        case .temporallyRelated: return "Temporally Related"
        case .topicallySimilar: return "Similar Topic"
        case .sourceRelated: return "Same Source"
        }
    }
}

struct RankedResult: Identifiable {
    let id: UUID = UUID()
    let contentItem: ContentItem
    let overallScore: Double
    let graphRelevance: Double
    let semanticRelevance: Double
    let explanations: [String]
}

// MARK: - Insight and Analytics Models

struct InsightCluster: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let items: [UUID]
    let confidence: Double
    let clusterType: ClusterType
    let createdAt: Date
    let keyInsights: [String] = []
    let actionableItems: [String] = []
}

struct GraphAnalytics {
    let nodeCount: Int
    let edgeCount: Int
    let averageDegree: Double
    let clusteringCoefficient: Double
    let diameter: Int
    let centralityScores: [UUID: Double]
    let communityStructure: [GraphCommunity]
    let temporalEvolution: [GraphSnapshot]
}

struct GraphCommunity: Identifiable {
    let id: UUID
    let nodes: Set<UUID>
    let strength: Double
    let topic: String?
    let representativeNodes: [UUID]
}

struct GraphSnapshot {
    let timestamp: Date
    let nodeCount: Int
    let edgeCount: Int
    let averageConnectivity: Double
    let majorClusters: [UUID]
}

// MARK: - Layout and Visualization Models

struct GraphLayout {
    var nodePositions: [UUID: CGPoint] = [:]
    var edgePaths: [UUID: UIBezierPath] = [:]
    var clusterBounds: [UUID: CGRect] = [:]
    let algorithm: LayoutAlgorithm
    let bounds: CGRect
    let parameters: LayoutParameters
}

struct LayoutParameters {
    var nodeSpacing: Double = 100.0
    var edgeLength: Double = 150.0
    var repulsionForce: Double = 1000.0
    var attractionForce: Double = 0.1
    var damping: Double = 0.9
    var iterations: Int = 100
    var temperature: Double = 100.0
    var coolingRate: Double = 0.95
}

struct GraphViewState {
    var selectedNodeId: UUID?
    var hoveredNodeId: UUID?
    var selectedClusterId: UUID?
    var visibilityFilters: Set<NodeType> = Set(NodeType.allCases)
    var strengthThreshold: Double = 0.0
    var showClusters: Bool = true
    var showLabels: Bool = true
    var animationDuration: Double = 0.3
}

// MARK: - Performance and Optimization Models

struct GraphPerformanceMetrics {
    let nodeRenderTime: TimeInterval
    let edgeRenderTime: TimeInterval
    let layoutComputeTime: TimeInterval
    let interactionResponseTime: TimeInterval
    let memoryUsage: Int64
    let frameRate: Double
}

struct GraphOptimizationSettings {
    var maxVisibleNodes: Int = 500
    var maxVisibleEdges: Int = 1000
    var levelOfDetailThreshold: Double = 0.1
    var frustumCulling: Bool = true
    var edgeBundling: Bool = false
    var nodeAggregation: Bool = true
    var dynamicLoading: Bool = true
}

// MARK: - Import/Export Models

struct GraphExportFormat {
    let format: ExportFormat
    let includeMetadata: Bool
    let includeLayout: Bool
    let compression: CompressionType
    
    enum ExportFormat {
        case json, graphml, gexf, csv, cytoscape
    }
    
    enum CompressionType {
        case none, gzip, lz4
    }
}

struct GraphImportResult {
    let nodesImported: Int
    let edgesImported: Int
    let clustersImported: Int
    let errors: [ImportError]
    let warnings: [ImportWarning]
}

struct ImportError {
    let line: Int?
    let description: String
    let severity: ErrorSeverity
    
    enum ErrorSeverity {
        case warning, error, critical
    }
}

struct ImportWarning {
    let description: String
    let affectedItems: [UUID]
}

// MARK: - Extensions and Utilities

extension GraphNode {
    var degree: Int {
        return metadata.connectionCount
    }
    
    func distanceTo(_ other: GraphNode) -> Double {
        let dx = position.x - other.position.x
        let dy = position.y - other.position.y
        return sqrt(dx * dx + dy * dy)
    }
    
    func isConnectedTo(_ nodeId: UUID, in edges: [GraphEdge]) -> Bool {
        return edges.contains { edge in
            (edge.fromId == self.id && edge.toId == nodeId) ||
            (edge.toId == self.id && edge.fromId == nodeId && edge.bidirectional)
        }
    }
}

extension GraphEdge {
    var length: Double {
        // This would be calculated based on actual node positions
        return 150.0 // Default length
    }
    
    func containsNode(_ nodeId: UUID) -> Bool {
        return fromId == nodeId || toId == nodeId
    }
    
    func otherNode(from nodeId: UUID) -> UUID? {
        if fromId == nodeId {
            return toId
        } else if toId == nodeId {
            return fromId
        }
        return nil
    }
}

extension GraphCluster {
    var nodeCount: Int {
        return nodeIds.count
    }
    
    func contains(nodeId: UUID) -> Bool {
        return nodeIds.contains(nodeId)
    }
    
    func overlaps(with other: GraphCluster) -> Bool {
        return !nodeIds.isDisjoint(with: other.nodeIds)
    }
}

// MARK: - Graph Algorithm Support

struct PathFindingResult {
    let path: [UUID]
    let totalDistance: Double
    let algorithm: PathFindingAlgorithm
}

enum PathFindingAlgorithm {
    case dijkstra, aStar, breadthFirst, depthFirst
}

struct CentralityMeasures {
    let degreeCentrality: Double
    let closenessCentrality: Double
    let betweennessCentrality: Double
    let eigenvectorCentrality: Double
    let pageRankScore: Double
}

struct GraphStatistics {
    let nodeCount: Int
    let edgeCount: Int
    let averageDegree: Double
    let density: Double
    let diameter: Int
    let averagePathLength: Double
    let clusteringCoefficient: Double
    let connectedComponents: Int
    let stronglyConnectedComponents: Int
}

// MARK: - Indexed Item for Search
struct IndexedItem {
    let id: UUID
    let tokens: Set<String>
    let timestamp: Date
}