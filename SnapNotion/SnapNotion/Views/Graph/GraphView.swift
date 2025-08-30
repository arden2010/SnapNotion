//
//  GraphView.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI

struct GraphView: View {
    @State private var selectedNode: GraphNode?
    @State private var graphNodes: [GraphNode] = GraphNode.sampleNodes
    @State private var showingSearch = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Graph Controls
                HStack {
                    Button("Reset View") {
                        selectedNode = nil
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Search") {
                        showingSearch = true
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Main Graph Area
                if graphNodes.isEmpty {
                    GraphEmptyState()
                } else {
                    GraphCanvasView(
                        nodes: graphNodes,
                        selectedNode: $selectedNode
                    )
                }
                
                // Selected Node Details
                if let selected = selectedNode {
                    NodeDetailView(node: selected)
                        .transition(.move(edge: .bottom))
                }
            }
            .navigationTitle("Knowledge Graph")
        }
        .sheet(isPresented: $showingSearch) {
            GraphSearchView(nodes: graphNodes) { node in
                selectedNode = node
                showingSearch = false
            }
        }
    }
}

struct GraphNode: Identifiable {
    let id = UUID()
    let title: String
    let type: NodeType
    let connections: [UUID]
    let position: CGPoint
    let weight: Double
    
    enum NodeType: String, CaseIterable {
        case content = "Content"
        case tag = "Tag"
        case task = "Task"
        case relation = "Relation"
        
        var color: Color {
            switch self {
            case .content: return .blue
            case .tag: return .green
            case .task: return .orange
            case .relation: return .purple
            }
        }
        
        var icon: String {
            switch self {
            case .content: return "doc.text"
            case .tag: return "tag"
            case .task: return "checkmark.circle"
            case .relation: return "link"
            }
        }
    }
    
    static let sampleNodes: [GraphNode] = [
        GraphNode(title: "AI Research", type: .content, connections: [], position: CGPoint(x: 100, y: 100), weight: 0.8),
        GraphNode(title: "Machine Learning", type: .tag, connections: [], position: CGPoint(x: 200, y: 150), weight: 0.6),
        GraphNode(title: "Review Papers", type: .task, connections: [], position: CGPoint(x: 150, y: 200), weight: 0.4),
        GraphNode(title: "Deep Learning", type: .content, connections: [], position: CGPoint(x: 250, y: 100), weight: 0.7)
    ]
}

struct GraphCanvasView: View {
    let nodes: [GraphNode]
    @Binding var selectedNode: GraphNode?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Nodes
                ForEach(nodes) { node in
                    NodeView(
                        node: node,
                        isSelected: selectedNode?.id == node.id
                    )
                    .position(
                        x: min(max(node.position.x, 50), geometry.size.width - 50),
                        y: min(max(node.position.y, 50), geometry.size.height - 50)
                    )
                    .onTapGesture {
                        selectedNode = selectedNode?.id == node.id ? nil : node
                    }
                }
            }
        }
        .clipped()
    }
}

struct NodeView: View {
    let node: GraphNode
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(node.type.color.opacity(0.2))
                    .stroke(node.type.color, lineWidth: isSelected ? 3 : 1)
                    .frame(width: nodeSize, height: nodeSize)
                
                Image(systemName: node.type.icon)
                    .font(.system(size: nodeSize * 0.4))
                    .foregroundColor(node.type.color)
            }
            
            Text(node.title)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
    
    private var nodeSize: CGFloat {
        30 + (node.weight * 20)
    }
}

struct NodeDetailView: View {
    let node: GraphNode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: node.type.icon)
                    .foregroundColor(node.type.color)
                Text(node.title)
                    .font(.headline)
                Spacer()
                Text(node.type.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(node.type.color.opacity(0.2))
                    .foregroundColor(node.type.color)
                    .cornerRadius(4)
            }
            
            Text("Weight: \(Int(node.weight * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Connections: \(node.connections.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding()
    }
}

struct GraphEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain")
                .font(.system(size: 64))
                .foregroundColor(.purple)
            
            Text("No Knowledge Graph Yet")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Your knowledge graph will appear here as you capture and organize content")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct GraphSearchView: View {
    let nodes: [GraphNode]
    let onSelectNode: (GraphNode) -> Void
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            List(filteredNodes) { node in
                Button(action: { onSelectNode(node) }) {
                    HStack {
                        Image(systemName: node.type.icon)
                            .foregroundColor(node.type.color)
                        Text(node.title)
                        Spacer()
                        Text(node.type.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Search Graph")
            .searchable(text: $searchText, prompt: "Search nodes...")
        }
    }
    
    private var filteredNodes: [GraphNode] {
        if searchText.isEmpty {
            return nodes
        } else {
            return nodes.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }
}

/*
#Preview {
    GraphView()
}
*/