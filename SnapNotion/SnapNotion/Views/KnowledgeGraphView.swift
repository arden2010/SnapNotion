//
//  KnowledgeGraphView.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI

struct KnowledgeGraphView: View {
    @StateObject private var graphManager = GraphManager()
    @State private var selectedNode: KnowledgeGraphNode?
    @State private var showingGraphControls = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Graph visualization area
                    if graphManager.isLoading {
                        ProgressView("Building knowledge graph...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if graphManager.nodes.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "network")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("No knowledge graph yet")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            
                            Text("Your content connections will appear here")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        GraphVisualizationView(
                            nodes: graphManager.nodes,
                            connections: graphManager.connections,
                            selectedNode: $selectedNode
                        )
                    }
                }
                .navigationTitle("Knowledge Graph")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingGraphControls.toggle()
                        }) {
                            Image(systemName: "slider.horizontal.3")
                        }
                    }
                }
                
                // Graph controls overlay
                if showingGraphControls {
                    VStack {
                        Spacer()
                        GraphControlsView(
                            graphManager: graphManager,
                            isShowing: $showingGraphControls
                        )
                        .transition(.move(edge: .bottom))
                    }
                }
                
                // Node detail overlay
                if let selectedNode = selectedNode {
                    VStack {
                        Spacer()
                        KnowledgeNodeDetailView(
                            node: selectedNode,
                            onClose: { self.selectedNode = nil }
                        )
                        .transition(.move(edge: .bottom))
                    }
                }
            }
        }
        .onAppear {
            graphManager.loadGraph()
        }
    }
}

// MARK: - Graph Visualization View
struct GraphVisualizationView: View {
    let nodes: [KnowledgeGraphNode]
    let connections: [GraphConnection]
    @Binding var selectedNode: KnowledgeGraphNode?
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            // Connections (lines between nodes)
            ForEach(connections) { connection in
                GraphConnectionLine(
                    from: nodePosition(for: connection.fromNodeId),
                    to: nodePosition(for: connection.toNodeId),
                    strength: connection.strength
                )
            }
            
            // Nodes
            ForEach(nodes) { node in
                KnowledgeGraphNodeView(node: node)
                    .position(nodePosition(for: node.id))
                    .onTapGesture {
                        selectedNode = node
                    }
            }
        }
    }
    
    private func nodePosition(for nodeId: UUID) -> CGPoint {
        // Simple circular layout for now
        guard let index = nodes.firstIndex(where: { $0.id == nodeId }) else {
            return CGPoint(x: 200, y: 200)
        }
        
        let angle = Double(index) * 2 * .pi / Double(nodes.count)
        let radius: Double = 120
        let centerX: Double = 200
        let centerY: Double = 300
        
        return CGPoint(
            x: centerX + radius * cos(angle),
            y: centerY + radius * sin(angle)
        )
    }
}

// MARK: - Graph Node View
struct KnowledgeGraphNodeView: View {
    let node: KnowledgeGraphNode
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(node.type.color)
                .frame(width: node.size, height: node.size)
                .overlay(
                    Image(systemName: node.type.icon)
                        .foregroundColor(.white)
                        .font(.system(size: node.size * 0.4))
                )
            
            Text(node.title)
                .font(.caption2)
                .lineLimit(1)
                .frame(maxWidth: 60)
        }
    }
}

// MARK: - Graph Connection Line
struct GraphConnectionLine: View {
    let from: CGPoint
    let to: CGPoint
    let strength: Double
    
    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(
            Color.gray.opacity(0.3 + strength * 0.7),
            lineWidth: 1 + strength * 2
        )
    }
}

// MARK: - Graph Controls View
struct GraphControlsView: View {
    @ObservedObject var graphManager: GraphManager
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Graph Controls")
                    .font(.headline)
                
                Spacer()
                
                Button("Done") {
                    isShowing = false
                }
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Layout Style")
                    Spacer()
                    Picker("Layout", selection: $graphManager.layoutStyle) {
                        ForEach(GraphLayoutStyle.allCases, id: \.self) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(maxWidth: 200)
                }
                
                HStack {
                    Text("Connection Strength")
                    Spacer()
                    Slider(value: $graphManager.connectionThreshold, in: 0...1)
                        .frame(maxWidth: 150)
                }
                
                HStack {
                    Text("Node Size")
                    Spacer()
                    Slider(value: $graphManager.nodeScale, in: 0.5...2.0)
                        .frame(maxWidth: 150)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding()
    }
}

// MARK: - Node Detail View
struct KnowledgeNodeDetailView: View {
    let node: KnowledgeGraphNode
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(node.type.color)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: node.type.icon)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                            )
                        
                        Text(node.title)
                            .font(.headline)
                    }
                    
                    Text(node.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Close") {
                    onClose()
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Connections: \(node.connectionCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Type: \(node.type.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(node.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding()
    }
}

// MARK: - Graph Manager
class GraphManager: ObservableObject {
    @Published var nodes: [KnowledgeGraphNode] = []
    @Published var connections: [GraphConnection] = []
    @Published var isLoading = false
    @Published var layoutStyle: GraphLayoutStyle = .circular
    @Published var connectionThreshold: Double = 0.3
    @Published var nodeScale: Double = 1.0
    
    func loadGraph() {
        isLoading = true
        
        // Simulate loading graph data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.generateSampleGraph()
            self.isLoading = false
        }
    }
    
    private func generateSampleGraph() {
        // Sample nodes
        nodes = [
            KnowledgeGraphNode(
                id: UUID(),
                title: "Project Ideas",
                description: "Collection of project concepts",
                type: .content,
                size: 40,
                connectionCount: 3,
                createdAt: Date()
            ),
            KnowledgeGraphNode(
                id: UUID(),
                title: "Research Notes",
                description: "Academic research materials",
                type: .content,
                size: 35,
                connectionCount: 2,
                createdAt: Date().addingTimeInterval(-86400)
            ),
            KnowledgeGraphNode(
                id: UUID(),
                title: "Meeting Action Items",
                description: "Tasks from team meetings",
                type: .task,
                size: 30,
                connectionCount: 1,
                createdAt: Date().addingTimeInterval(-3600)
            )
        ]
        
        // Sample connections
        if nodes.count >= 3 {
            connections = [
                GraphConnection(
                    id: UUID(),
                    fromNodeId: nodes[0].id,
                    toNodeId: nodes[1].id,
                    strength: 0.8,
                    type: .semantic
                ),
                GraphConnection(
                    id: UUID(),
                    fromNodeId: nodes[1].id,
                    toNodeId: nodes[2].id,
                    strength: 0.6,
                    type: .derived
                )
            ]
        }
    }
}

// MARK: - Data Models
struct KnowledgeGraphNode: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let type: KnowledgeNodeType
    let size: CGFloat
    let connectionCount: Int
    let createdAt: Date
}

struct GraphConnection: Identifiable {
    let id: UUID
    let fromNodeId: UUID
    let toNodeId: UUID
    let strength: Double
    let type: ConnectionType
}

enum KnowledgeNodeType: CaseIterable {
    case content
    case task
    case concept
    
    var color: Color {
        switch self {
        case .content: return .blue
        case .task: return .orange
        case .concept: return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .content: return "doc.text"
        case .task: return "checkmark"
        case .concept: return "lightbulb"
        }
    }
    
    var displayName: String {
        switch self {
        case .content: return "Content"
        case .task: return "Task"
        case .concept: return "Concept"
        }
    }
}

enum ConnectionType {
    case semantic
    case derived
    case related
}

enum GraphLayoutStyle: CaseIterable {
    case circular
    case force
    case hierarchical
    
    var displayName: String {
        switch self {
        case .circular: return "Circle"
        case .force: return "Force"
        case .hierarchical: return "Tree"
        }
    }
}

#Preview {
    KnowledgeGraphView()
}