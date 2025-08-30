//
//  RightPanelView.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI

struct RightPanelView: View {
    @EnvironmentObject var navigationController: NavigationController
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            rightPanelHeader
            
            // Advanced Features
            ScrollView {
                VStack(spacing: 20) {
                    // Knowledge Graph Section
                    knowledgeGraphSection
                    
                    // AI Tools Section
                    aiToolsSection
                    
                    // Analytics Section
                    analyticsSection
                    
                    // Plugins Section
                    pluginsSection
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
    }
    
    // MARK: - Header
    private var rightPanelHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Advanced")
                    .claudeCodeStyle(.header2, color: .primary)
                
                Text("Power user features")
                    .claudeCodeStyle(.caption, color: .secondary)
            }
            
            Spacer()
            
            Button("Done") {
                navigationController.returnToMainPanel()
            }
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Knowledge Graph Section
    private var knowledgeGraphSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Knowledge Graph", icon: "network", color: .purple)
            
            VStack(spacing: 8) {
                AdvancedFeatureCard(
                    icon: "point.3.connected.trianglepath.dotted",
                    title: "Graph Visualization",
                    subtitle: "Explore content relationships",
                    color: .purple,
                    comingSoon: true
                )
                
                AdvancedFeatureCard(
                    icon: "link",
                    title: "Bidirectional Links",
                    subtitle: "Connect related content",
                    color: .purple,
                    comingSoon: true
                )
                
                AdvancedFeatureCard(
                    icon: "circle.hexagongrid.fill",
                    title: "Content Clustering",
                    subtitle: "AI-powered grouping",
                    color: .purple,
                    comingSoon: true
                )
            }
        }
    }
    
    // MARK: - AI Tools Section
    private var aiToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "AI Tools", icon: "brain.head.profile", color: .blue)
            
            VStack(spacing: 8) {
                AdvancedFeatureCard(
                    icon: "text.magnifyingglass",
                    title: "Semantic Search",
                    subtitle: "Natural language queries",
                    color: .blue,
                    comingSoon: true
                )
                
                AdvancedFeatureCard(
                    icon: "doc.text.magnifyingglass",
                    title: "Content Analysis",
                    subtitle: "Deep content understanding",
                    color: .blue,
                    comingSoon: false
                )
                
                AdvancedFeatureCard(
                    icon: "pencil.and.scribble",
                    title: "Writing Assistant",
                    subtitle: "AI-powered writing help",
                    color: .blue,
                    comingSoon: true
                )
            }
        }
    }
    
    // MARK: - Analytics Section
    private var analyticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Analytics", icon: "chart.bar.fill", color: .green)
            
            VStack(spacing: 8) {
                // Quick Stats
                HStack(spacing: 16) {
                    StatCard(title: "Items", value: "0", color: .green)
                    StatCard(title: "Storage", value: "2.1 GB", color: .orange)
                    StatCard(title: "This Week", value: "0", color: .blue)
                }
                
                AdvancedFeatureCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Usage Trends",
                    subtitle: "Capture and search patterns",
                    color: .green,
                    comingSoon: true
                )
                
                AdvancedFeatureCard(
                    icon: "clock.arrow.circlepath",
                    title: "Activity Timeline",
                    subtitle: "Content creation history",
                    color: .green,
                    comingSoon: true
                )
            }
        }
    }
    
    // MARK: - Plugins Section
    private var pluginsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Plugins", icon: "puzzlepiece.extension.fill", color: .orange)
            
            VStack(spacing: 8) {
                AdvancedFeatureCard(
                    icon: "calendar.badge.plus",
                    title: "Calendar Integration",
                    subtitle: "Sync with system calendar",
                    color: .orange,
                    comingSoon: true
                )
                
                AdvancedFeatureCard(
                    icon: "reminder",
                    title: "Reminders Sync",
                    subtitle: "Task integration",
                    color: .orange,
                    comingSoon: true
                )
                
                AdvancedFeatureCard(
                    icon: "square.and.arrow.up.on.square",
                    title: "Third-party Apps",
                    subtitle: "External integrations",
                    color: .orange,
                    comingSoon: true
                )
            }
        }
    }
    
    // MARK: - Helper Views
    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(title)
                .claudeCodeStyle(.header3, color: .primary)
            
            Spacer()
        }
    }
}

// MARK: - Advanced Feature Card
struct AdvancedFeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    var comingSoon: Bool = false
    
    var body: some View {
        Button(action: { /* TODO: Implement feature */ }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title)
                            .claudeCodeStyle(.body, color: comingSoon ? .secondary : .primary)
                        
                        if comingSoon {
                            Text("SOON")
                                .claudeCodeStyle(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(color)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    
                    Text(subtitle)
                        .claudeCodeStyle(.caption, color: .secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if !comingSoon {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(comingSoon)
    }
}

// MARK: - StatCard moved to dedicated file
// StatCard is now in Views/Components/StatCard.swift

#Preview {
    RightPanelView()
        .environmentObject(NavigationController())
}