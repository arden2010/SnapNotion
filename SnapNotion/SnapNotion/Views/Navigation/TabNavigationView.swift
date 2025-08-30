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
        case .dashboard: return "Dashboard"
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

// MARK: - Tab Content Views
struct DashboardView: View {
    @StateObject private var contentViewModel = ContentViewModel()
    @StateObject private var clipboardMonitor = ClipboardMonitor()
    @StateObject private var screenshotDetector = ScreenCaptureDetector()
    
    @State private var showingCaptureSheet = false
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var showingDocumentScanner = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Quick Stats
                    quickStatsSection
                    
                    // Recent Activity with real content
                    recentActivitySection
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .refreshable {
                await contentViewModel.refreshContent()
            }
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton {
                        showingCaptureSheet = true
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showingCaptureSheet) {
            QuickCaptureView(
                clipboardMonitor: clipboardMonitor,
                screenshotDetector: screenshotDetector,
                onCameraCapture: { showingCamera = true },
                onPhotoLibrary: { showingPhotoLibrary = true },
                onDocumentScan: { showingDocumentScanner = true },
                onClipboardPaste: { handleClipboardContent() },
                onScreenshotCapture: { handleRecentScreenshot() }
            )
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraCaptureView(
                isPresented: $showingCamera,
                onImageCaptured: { data in handleCapturedImage(data, source: .camera) },
                onError: { error in showError(error) }
            )
        }
        .sheet(isPresented: $showingPhotoLibrary) {
            PhotoLibraryPicker(
                isPresented: $showingPhotoLibrary,
                onImageSelected: { data in handleCapturedImage(data, source: .photos) },
                onError: { error in showError(error) }
            )
        }
        .fullScreenCover(isPresented: $showingDocumentScanner) {
            if #available(iOS 13.0, *) {
                DocumentScannerView(
                    isPresented: $showingDocumentScanner,
                    onDocumentScanned: { dataArray in handleScannedDocuments(dataArray) },
                    onError: { error in showError(error) }
                )
            }
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            setupNotifications()
        }
    }
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Stats")
                .claudeCodeStyle(.header3, color: .primary)
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Total Items", 
                    value: "\(contentViewModel.filteredItems.count)", 
                    color: .blue
                )
                StatCard(
                    title: "This Week", 
                    value: "\(contentViewModel.recentItemsCount)", 
                    color: .green
                )
                StatCard(
                    title: "Favorites", 
                    value: "\(contentViewModel.favoriteItemsCount)", 
                    color: .red
                )
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .claudeCodeStyle(.header3, color: .primary)
            
            if contentViewModel.filteredItems.isEmpty {
                VStack(spacing: 8) {
                    EmptyStateView(
                        icon: "clock",
                        title: "No Recent Activity",
                        subtitle: "Start capturing content to see your activity here"
                    )
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            } else {
                VStack(spacing: 0) {
                    ForEach(contentViewModel.recentItems.prefix(5)) { item in
                        ContentRowView(
                            item: item,
                            onFavoriteToggle: { contentViewModel.toggleFavorite(for: item) },
                            onDelete: { contentViewModel.deleteItem(item) }
                        )
                        
                        if item.id != contentViewModel.recentItems.prefix(5).last?.id {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Content Processing Methods
    private func handleCapturedImage(_ data: Data, source: AppSource) {
        let sharedContent = SharedContent(
            type: .image,
            data: data,
            text: nil,
            url: nil,
            sourceApp: source,
            metadata: ["captureMethod": "direct", "timestamp": Date().timeIntervalSince1970]
        )
        
        Task {
            await contentViewModel.processSharedContent(sharedContent)
        }
    }
    
    private func handleScannedDocuments(_ dataArray: [Data]) {
        for data in dataArray {
            let sharedContent = SharedContent(
                type: .image,
                data: data,
                text: nil,
                url: nil,
                sourceApp: .camera,
                metadata: ["captureMethod": "document_scan", "timestamp": Date().timeIntervalSince1970]
            )
            
            Task {
                await contentViewModel.processSharedContent(sharedContent)
            }
        }
    }
    
    private func handleClipboardContent() {
        guard let content = clipboardMonitor.getClipboardContent() else {
            showError(NSError(domain: "SnapNotion", code: -1, userInfo: [NSLocalizedDescriptionKey: "No content found in clipboard"]))
            return
        }
        
        Task {
            await contentViewModel.processSharedContent(content)
        }
    }
    
    private func handleRecentScreenshot() {
        Task {
            if let screenshotData = await screenshotDetector.getLatestScreenshot() {
                let sharedContent = SharedContent(
                    type: .image,
                    data: screenshotData,
                    text: nil,
                    url: nil,
                    sourceApp: .photos,
                    metadata: ["captureMethod": "screenshot", "timestamp": Date().timeIntervalSince1970]
                )
                
                await contentViewModel.processSharedContent(sharedContent)
            } else {
                showError(NSError(domain: "SnapNotion", code: -1, userInfo: [NSLocalizedDescriptionKey: "No recent screenshot found"]))
            }
        }
    }
    
    private func showError(_ error: Error) {
        errorMessage = error.localizedDescription
        showingErrorAlert = true
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .init("SharedContentReceived"),
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let contentData = userInfo["content"] as? Data,
               let sharedContent = try? JSONDecoder().decode(SharedContent.self, from: contentData) {
                
                Task {
                    await contentViewModel.processSharedContent(sharedContent)
                }
            }
        }
    }
}

struct LibraryView: View {
    @StateObject private var contentViewModel = ContentViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            searchBar
            
            // Use the existing LegacyContentView functionality
            LegacyContentView()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search your library", text: $contentViewModel.searchText)
                .textFieldStyle(.plain)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct FavoritesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                EmptyStateView(
                    icon: "heart",
                    title: "No Favorites Yet",
                    subtitle: "Favorite items from your library to see them here"
                )
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct TasksView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Task Categories
                taskCategoriesSection
                
                // Active Tasks
                activeTasksSection
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var taskCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Task Categories")
                .claudeCodeStyle(.header3, color: .primary)
            
            HStack(spacing: 16) {
                TaskCategoryCard(title: "To Do", count: 0, color: .orange)
                TaskCategoryCard(title: "In Progress", count: 0, color: .blue)
                TaskCategoryCard(title: "Completed", count: 0, color: .green)
            }
        }
    }
    
    private var activeTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Tasks")
                .claudeCodeStyle(.header3, color: .primary)
            
            VStack(spacing: 8) {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "No Tasks Yet",
                    subtitle: "AI will generate tasks based on your captured content"
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

struct GraphView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Graph Controls
            graphControlsSection
            
            // Graph Visualization
            graphVisualizationSection
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    private var graphControlsSection: some View {
        HStack {
            Text("Knowledge Graph")
                .claudeCodeStyle(.header3, color: .primary)
            
            Spacer()
            
            Button("Settings") {
                // TODO: Graph settings
            }
            .foregroundColor(.phoenixOrange)
        }
    }
    
    private var graphVisualizationSection: some View {
        VStack(spacing: 16) {
            EmptyStateView(
                icon: "network",
                title: "Graph Coming Soon",
                subtitle: "Visualize connections between your content with an interactive knowledge graph"
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Helper Views
struct SuggestionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .claudeCodeStyle(.body, color: .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(subtitle)
                    .claudeCodeStyle(.caption, color: .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        Text(title)
            .font(.caption)
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.phoenixOrange : Color(.systemBackground))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(.separator), lineWidth: isSelected ? 0 : 1)
            )
    }
}

struct TaskCategoryCard: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(title)
                .claudeCodeStyle(.caption, color: .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - EmptyStateView
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.medium)
            
            Text(subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    TabNavigationView()
}