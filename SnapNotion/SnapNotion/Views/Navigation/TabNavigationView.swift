//
//  TabNavigationView.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI

struct TabNavigationView: View {
    @State private var selectedTab: TabType = .dashboard
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            tabBar
            
            // Tab Content
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(TabType.dashboard)
                
                LibraryView()
                    .tag(TabType.library)
                
                FavoritesView()
                    .tag(TabType.favorites)
                
                TasksView()
                    .tag(TabType.tasks)
                
                GraphView()
                    .tag(TabType.graph)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
        }
    }
    
    // MARK: - Tab Bar
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(TabType.allCases, id: \.self) { tab in
                TabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: { selectedTab = tab }
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}

// MARK: - Tab Type
enum TabType: String, CaseIterable {
    case dashboard = "dashboard"
    case library = "library"
    case favorites = "favorites"
    case tasks = "tasks"
    case graph = "graph"
    
    var title: String {
        switch self {
        case .dashboard: return "Inbox"
        case .library: return "Library"
        case .favorites: return "Favorites"
        case .tasks: return "Tasks"
        case .graph: return "Graph"
        }
    }
    
    var icon: String {
        switch self {
        case .dashboard: return "house"
        case .library: return "books.vertical"
        case .favorites: return "heart"
        case .tasks: return "checkmark.circle"
        case .graph: return "network"
        }
    }
    
    var activeIcon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .library: return "books.vertical.fill"
        case .favorites: return "heart.fill"
        case .tasks: return "checkmark.circle.fill"
        case .graph: return "network"
        }
    }
}

// MARK: - Tab Bar Item
struct TabBarItem: View {
    let tab: TabType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.activeIcon : tab.icon)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .phoenixOrange : .secondary)
                
                Text(tab.title)
                    .claudeCodeStyle(.caption, color: isSelected ? .accent : .secondary)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

