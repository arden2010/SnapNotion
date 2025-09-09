//
//  MainContentView.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI

struct MainContentView: View {
    let onNavigateToTasks: () -> Void
    
    @StateObject private var contentManager = ContentManager.shared
    @StateObject private var clipboardMonitor = ClipboardMonitor()
    @StateObject private var screenshotDetector = ScreenshotDetectionManager.shared
    @StateObject private var taskManager = TaskManager()
    
    init(onNavigateToTasks: @escaping () -> Void = {}) {
        self.onNavigateToTasks = onNavigateToTasks
    }
    
    @State private var showingAddSheet = false
    @State private var showingOptionsMenu = false
    @State private var selectedViewStyle: ContentViewStyle = .standard
    @State private var selectedContent: ContentNodeData?
    @State private var showingDetailView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Smart Suggestions for Clipboard and Screenshot
                    SmartSuggestionsView(
                        clipboardMonitor: clipboardMonitor,
                        screenshotDetector: screenshotDetector,
                        onClipboardPaste: {
                            handleClipboardPaste()
                        },
                        onScreenshotCapture: {
                            handleScreenshotCapture()
                        }
                    )
                    .padding(.horizontal)
                    
                    // Inbox View - Shows tasks and content by sources separately
                    InboxContentView(
                        viewStyle: selectedViewStyle, 
                        contentManager: contentManager, 
                        taskManager: taskManager,
                        onContentTap: handleContentTap,
                        onFavoriteToggle: handleFavoriteToggle,
                        onContentDelete: handleContentDelete,
                        onNavigateToTasks: onNavigateToTasks
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .navigationTitle("Inbox")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 8) {
                            // View Style Buttons
                            ForEach(ContentViewStyle.allCases, id: \.self) { style in
                                Button(action: {
                                    selectedViewStyle = style
                                }) {
                                    Image(systemName: style.icon)
                                        .foregroundColor(selectedViewStyle == style ? .phoenixOrange : .gray)
                                        .font(.system(size: 16, weight: selectedViewStyle == style ? .semibold : .regular))
                                }
                            }
                        }
                    }
                }
                
                // Smart Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        SmartFloatingActionButton(
                            onPaste: {
                                handleSmartPasteAction()
                            },
                            onLongPress: {
                                showingOptionsMenu = true
                            }
                        )
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddContentSheet()
        }
        .sheet(isPresented: $showingOptionsMenu) {
            ContentOptionsMenu()
        }
        .sheet(isPresented: $showingDetailView) {
            if let content = selectedContent {
                ContentDetailView(content: content, contentManager: contentManager)
            }
        }
        .overlay {
            if contentManager.isProcessing {
                ProcessingOverlay(message: "Processing content...")
            }
        }
        .onAppear {
            // Load content when view appears
        }
    }
    
    // MARK: - Action Handlers
    private func handleClipboardPaste() {
        Task {
            if let _ = try? await contentManager.createContentFromClipboard() {
                // Content successfully processed from clipboard
            }
        }
    }
    
    private func handleScreenshotCapture() {
        // Screenshot capture is handled automatically by ScreenshotDetectionManager
        print("Screenshot capture triggered from UI")
    }
    
    private func handleSmartPasteAction() {
        Task {
            if let _ = try? await contentManager.createContentFromClipboard() {
                // Content successfully processed from clipboard
            }
        }
    }
    
    // MARK: - Content Interaction Handlers
    
    private func handleContentTap(_ content: ContentNodeData) {
        selectedContent = content
        showingDetailView = true
    }
    
    private func handleFavoriteToggle(for contentId: UUID) {
        // TODO: Implement favorite toggle in ContentManager
        print("Toggle favorite for content: \(contentId)")
        // For now, just reload content
        contentManager.loadAllContent()
    }
    
    private func handleContentDelete(_ contentId: UUID) {
        // TODO: Implement deletion in ContentManager
        print("Delete content: \(contentId)")
        // For now, just reload content
        contentManager.loadAllContent()
    }
}

// MARK: - View Style Enum
enum ContentViewStyle: String, CaseIterable {
    case standard = "standard"
    case compact = "compact" 
    case detailed = "detailed"
    case grid = "grid"
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .compact: return "Compact"
        case .detailed: return "Detailed"
        case .grid: return "Grid"
        }
    }
    
    var icon: String {
        switch self {
        case .standard: return "list.bullet"
        case .compact: return "list.dash"
        case .detailed: return "list.bullet.rectangle"
        case .grid: return "square.grid.2x2"
        }
    }
}

// MARK: - Grid Content Card
struct GridContentCard: View {
    let item: ContentItem
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: item.type.icon)
                    .foregroundColor(item.type.color)
                    .font(.title3)
                
                Spacer()
                
                if item.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(item.preview)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            HStack {
                Text(item.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Circle()
                    .fill(item.processingStatusType.color)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(12)
        .frame(height: 160)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Compact Content Row
struct CompactContentRowView: View {
    let item: ContentItem
    let onFavoriteToggle: () -> Void
    let onDelete: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.type.icon)
                .foregroundColor(item.type.color)
                .font(.subheadline)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(item.preview)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if item.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption2)
                }
                
                Text(item.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Detailed Content Row
struct DetailedContentRowView: View {
    let item: ContentItem
    let onFavoriteToggle: () -> Void
    let onDelete: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: item.type.icon)
                        .foregroundColor(item.type.color)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(item.source)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if item.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                    
                    Text(item.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(item.preview)
                .font(.body)
                .lineLimit(4)
            
            if !item.attachments.isEmpty {
                HStack {
                    Image(systemName: "paperclip")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(item.attachments.count) attachment\(item.attachments.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(item.processingStatusType.color)
                        .frame(width: 6, height: 6)
                    
                    Text(item.processingStatus.capitalized)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(item.sourceApp.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Context Menu
struct ContentContextMenu: View {
    let item: ContentItem
    let onFavoriteToggle: () -> Void
    let onEdit: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void
    
    @ViewBuilder var body: some View {
        Button(action: {
            // Handle view details
        }) {
            Label("View Details", systemImage: "info.circle")
        }
        
        Button(action: onEdit) {
            Label("Edit", systemImage: "pencil")
        }
        
        Button(action: onFavoriteToggle) {
            Label(
                item.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                systemImage: item.isFavorite ? "heart.slash" : "heart"
            )
        }
        
        Divider()
        
        Button(action: onShare) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        
        Button(action: {
            // Handle duplicate
        }) {
            Label("Duplicate", systemImage: "doc.on.doc")
        }
        
        Divider()
        
        Button(role: .destructive, action: onDelete) {
            Label("Delete", systemImage: "trash")
        }
    }
}

// MARK: - Inbox Content View
struct InboxContentView: View {
    let viewStyle: ContentViewStyle
    @ObservedObject var contentManager: ContentManager
    @ObservedObject var taskManager: TaskManager
    let onContentTap: (ContentNodeData) -> Void
    let onFavoriteToggle: (UUID) -> Void
    let onContentDelete: (UUID) -> Void
    let onNavigateToTasks: () -> Void
    
    var body: some View {
        switch viewStyle {
        case .standard:
            standardInboxView
        case .compact:
            compactInboxView
        case .detailed:
            detailedInboxView
        case .grid:
            gridInboxView
        }
    }
    
    // MARK: - Standard View
    private var standardInboxView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Tasks Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checklist")
                            .foregroundColor(.orange)
                            .font(.title3)
                        
                        Text("What's Next")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(taskManager.tasks.filter { !$0.isCompleted }.count) active")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if taskManager.tasks.count > 5 {
                                Button(action: {
                                    onNavigateToTasks()
                                }) {
                                    HStack(spacing: 4) {
                                        Text("View All")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    if taskManager.tasks.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle")
                                .font(.title2)
                                .foregroundColor(.green)
                            
                            Text("No tasks yet!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 80)
                        .frame(maxWidth: .infinity)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(taskManager.tasks.prefix(5)) { task in
                                TaskSummaryCard(
                                    task: task, 
                                    onNavigateToTasks: onNavigateToTasks,
                                    onTaskUpdate: { updatedTask in
                                        taskManager.updateTask(updatedTask)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Divider()
                    .padding(.horizontal)
                
                // Content by Source Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "folder.badge")
                            .foregroundColor(.blue)
                            .font(.title3)
                        
                        Text("Latest Captured")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("\(contentManager.allContent.count) items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    if contentManager.allContent.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "doc.badge.plus")
                                .font(.title2)
                                .foregroundColor(.gray)
                            
                            Text("No content captured yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 80)
                        .frame(maxWidth: .infinity)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(contentBySource, id: \.source) { sourceGroup in
                                SourceContentSection(
                                    sourceGroup: sourceGroup,
                                    onItemTap: { item in
                                        if let contentData = findContentData(for: item) {
                                            onContentTap(contentData)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer(minLength: 100) // Space for FAB
            }
        }
        .onAppear {
            // Content automatically loads via ContentManager
        }
    }
    
    // MARK: - Compact View
    private var compactInboxView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Compact Tasks Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checklist")
                            .foregroundColor(.orange)
                            .font(.subheadline)
                        
                        Text("What's Next")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text("\(taskManager.tasks.filter { !$0.isCompleted }.count)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            if taskManager.tasks.count > 3 {
                                Button(action: {
                                    onNavigateToTasks()
                                }) {
                                    HStack(spacing: 2) {
                                        Text("View All")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    if taskManager.tasks.isEmpty {
                        Text("All caught up!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    } else {
                        LazyVStack(spacing: 4) {
                            ForEach(taskManager.tasks.prefix(3)) { task in
                                CompactTaskRow(
                                    task: task, 
                                    onNavigateToTasks: onNavigateToTasks,
                                    onTaskUpdate: { updatedTask in
                                        taskManager.updateTask(updatedTask)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Divider()
                    .padding(.horizontal)
                
                // Compact Content Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "folder.badge")
                            .foregroundColor(.blue)
                            .font(.subheadline)
                        
                        Text("Latest Captured")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("\(contentManager.allContent.count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    LazyVStack(spacing: 4) {
                        ForEach(contentManager.allContent.prefix(8)) { item in
                            CompactContentRowView(
                                item: item.asContentItem(),
                                onFavoriteToggle: { onFavoriteToggle(item.id) },
                                onDelete: { onContentDelete(item.id) },
                                onTap: { onContentTap(item) }
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer(minLength: 100) // Space for FAB
            }
        }
        .onAppear {
            // Content automatically loads via ContentManager
        }
    }
    
    // MARK: - Detailed View
    private var detailedInboxView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Detailed Tasks Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checklist")
                            .foregroundColor(.orange)
                            .font(.title3)
                        
                        Text("What's Next")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(taskManager.tasks.filter { !$0.isCompleted }.count) active")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Text("\(taskManager.tasks.filter { $0.isCompleted }.count) completed")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                if taskManager.tasks.count > 5 {
                                    Button(action: {
                                        onNavigateToTasks()
                                    }) {
                                        HStack(spacing: 4) {
                                            Text("View All")
                                                .font(.caption2)
                                                .foregroundColor(.blue)
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.caption2)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    if taskManager.tasks.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle")
                                .font(.title3)
                                .foregroundColor(.green)
                            
                            Text("No tasks yet!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 60)
                        .frame(maxWidth: .infinity)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(taskManager.tasks.prefix(5)) { task in
                                DetailedTaskRow(
                                    task: task, 
                                    onNavigateToTasks: onNavigateToTasks,
                                    onTaskUpdate: { updatedTask in
                                        taskManager.updateTask(updatedTask)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Divider()
                    .padding(.horizontal)
                
                // Detailed Content Section with full source info
                ForEach(contentBySource, id: \.source) { sourceGroup in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: sourceGroup.source.icon)
                                .foregroundColor(sourceGroup.source.color)
                                .font(.title3)
                            
                            Text(sourceGroup.source.displayName)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Text("\(sourceGroup.items.count) items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(sourceGroup.items) { item in
                                DetailedContentRowView(
                                    item: item,
                                    onFavoriteToggle: { onFavoriteToggle(item.id) },
                                    onDelete: { onContentDelete(item.id) },
                                    onTap: {
                                        if let contentData = findContentData(for: item) {
                                            onContentTap(contentData)
                                        }
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 100) // Space for FAB
            }
        }
        .onAppear {
            // Content automatically loads via ContentManager
        }
    }
    
    // MARK: - Grid View
    private var gridInboxView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Grid Tasks Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checklist")
                            .foregroundColor(.orange)
                            .font(.title3)
                        
                        Text("What's Next")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text("\(taskManager.tasks.filter { !$0.isCompleted }.count) active")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if taskManager.tasks.count > 5 {
                                Button(action: {
                                    onNavigateToTasks()
                                }) {
                                    HStack(spacing: 4) {
                                        Text("View All")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    if taskManager.tasks.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle")
                                .font(.title2)
                                .foregroundColor(.green)
                            
                            Text("No tasks yet!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 80)
                        .frame(maxWidth: .infinity)
                    } else {
                        // Tasks in horizontal scroll
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(taskManager.tasks.prefix(5)) { task in
                                    GridTaskCard(
                                        task: task, 
                                        onNavigateToTasks: onNavigateToTasks,
                                        onTaskUpdate: { updatedTask in
                                            taskManager.updateTask(updatedTask)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Divider()
                    .padding(.horizontal)
                
                // Grid Content Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "folder.badge")
                            .foregroundColor(.blue)
                            .font(.title3)
                        
                        Text("Latest Captured")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("\(contentManager.allContent.count) items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(contentManager.allContent.prefix(10)) { item in
                            GridContentCard(item: item.asContentItem()) {
                                onContentTap(item)
                            }
                                .contextMenu {
                                    ContentContextMenu(
                                        item: item.asContentItem(),
                                        onFavoriteToggle: { onFavoriteToggle(item.id) },
                                        onEdit: { /* Handle edit */ },
                                        onShare: { /* Handle share */ },
                                        onDelete: { onContentDelete(item.id) }
                                    )
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 100) // Space for FAB
            }
        }
        .onAppear {
            // Content automatically loads via ContentManager
        }
    }
    
    // Group content by source
    private var contentBySource: [ContentSourceGroup] {
        let grouped = Dictionary(grouping: contentManager.allContent) { $0.source }
        return grouped.compactMap { (source, items) in
            ContentSourceGroup(
                source: AppSource(rawValue: source) ?? .other,
                items: Array(items.sorted { $0.timestamp > $1.timestamp }.prefix(5).map { $0.asContentItem() }) // Show max 5 items per source, sorted by newest first
            )
        }.sorted { $0.source.displayName < $1.source.displayName }
    }
    
    // Helper function to find ContentNodeData from ContentItem
    private func findContentData(for contentItem: ContentItem) -> ContentNodeData? {
        return contentManager.allContent.first { $0.id == contentItem.id }
    }
}

// MARK: - Source Content Section
struct SourceContentSection: View {
    let sourceGroup: ContentSourceGroup
    let onItemTap: (ContentItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Source Header
            HStack {
                Image(systemName: sourceGroup.source.icon)
                    .foregroundColor(sourceGroup.source.color)
                    .font(.title3)
                
                Text(sourceGroup.source.displayName)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(sourceGroup.items.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(6)
            }
            
            // Content Items
            ForEach(sourceGroup.items) { item in
                Button(action: {
                    onItemTap(item)
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: item.type.icon)
                            .foregroundColor(item.type.color)
                            .font(.subheadline)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Text(item.preview)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            if item.isFavorite {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                    .font(.caption2)
                            }
                            
                            Text(item.timestamp, style: .relative)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Circle()
                                .fill(item.processingStatusType.color)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                
                if sourceGroup.items.last?.id != item.id {
                    Divider()
                        .padding(.leading, 36)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Legacy InboxDashboardView removed - functionality moved to InboxContentView

// MARK: - Task Summary Card
struct TaskSummaryCard: View {
    let task: SimpleTaskItem
    let onNavigateToTasks: () -> Void
    let onTaskUpdate: (SimpleTaskItem) -> Void
    @State private var showingEditSheet = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                toggleTaskCompletion()
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                HStack {
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            
                            Text(dueDate, style: .relative)
                                .font(.caption2)
                        }
                        .foregroundColor(dueDate < Date() ? .red : .secondary)
                    }
                    
                    Spacer()
                    
                    PriorityBadge(priority: task.priority)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            showingEditSheet = true
        }
        .contextMenu {
            Button(action: {
                showingEditSheet = true
            }) {
                Label("Edit Task", systemImage: "pencil")
            }
            
            Button(action: toggleTaskCompletion) {
                Label(task.isCompleted ? "Mark Incomplete" : "Mark Complete", 
                      systemImage: task.isCompleted ? "circle" : "checkmark.circle")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            TaskEditView(task: task) { updatedTask in
                onTaskUpdate(updatedTask)
            }
        }
    }
    
    private func toggleTaskCompletion() {
        let updatedTask = SimpleTaskItem(
            id: task.id,
            title: task.title,
            description: task.description,
            isCompleted: !task.isCompleted,
            priority: task.priority,
            dueDate: task.dueDate,
            createdAt: task.createdAt
        )
        onTaskUpdate(updatedTask)
    }
}

// MARK: - Priority Badge
struct PriorityBadge: View {
    let priority: SimpleTaskItem.TaskPriority
    
    var body: some View {
        Text(priority.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priority.color.opacity(0.2))
            .foregroundColor(priority.color)
            .cornerRadius(4)
    }
}

// MARK: - Content Source Section
struct ContentSourceSection: View {
    let sourceGroup: ContentSourceGroup
    let onItemTap: (ContentItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: sourceGroup.source.icon)
                    .foregroundColor(sourceGroup.source.color)
                    .font(.subheadline)
                
                Text(sourceGroup.source.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            ForEach(sourceGroup.items) { item in
                Button(action: {
                    onItemTap(item)
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: item.type.icon)
                            .foregroundColor(item.type.color)
                            .font(.caption)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Text(item.timestamp, style: .relative)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if item.isFavorite {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.caption2)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Supporting Models
struct ContentSourceGroup {
    let source: AppSource
    let items: [ContentItem]
}

extension SimpleTaskItem.TaskPriority {
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Med"
        case .high: return "High"
        }
    }
}

// MARK: - Legacy Views Removed
// GridInboxView, CompactInboxView, and DetailedInboxView functionality moved to InboxContentView

// MARK: - Compact Task Row
struct CompactTaskRow: View {
    let task: SimpleTaskItem
    let onNavigateToTasks: () -> Void
    let onTaskUpdate: (SimpleTaskItem) -> Void
    @State private var showingEditSheet = false
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: toggleTaskCompletion) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            
            HStack {
                Text(task.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let dueDate = task.dueDate {
                    Text(dueDate, style: .relative)
                        .font(.caption2)
                        .foregroundColor(dueDate < Date() ? .red : .secondary)
                }
                
                Circle()
                    .fill(task.priority.color)
                    .frame(width: 4, height: 4)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showingEditSheet = true
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(6)
        .contextMenu {
            Button(action: {
                showingEditSheet = true
            }) {
                Label("Edit Task", systemImage: "pencil")
            }
            
            Button(action: toggleTaskCompletion) {
                Label(task.isCompleted ? "Mark Incomplete" : "Mark Complete", 
                      systemImage: task.isCompleted ? "circle" : "checkmark.circle")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            TaskEditView(task: task) { updatedTask in
                onTaskUpdate(updatedTask)
            }
        }
    }
    
    private func toggleTaskCompletion() {
        let updatedTask = SimpleTaskItem(
            id: task.id,
            title: task.title,
            description: task.description,
            isCompleted: !task.isCompleted,
            priority: task.priority,
            dueDate: task.dueDate,
            createdAt: task.createdAt
        )
        onTaskUpdate(updatedTask)
    }
}

// MARK: - Grid Task Card
struct GridTaskCard: View {
    let task: SimpleTaskItem
    let onNavigateToTasks: () -> Void
    let onTaskUpdate: (SimpleTaskItem) -> Void
    @State private var showingEditSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(action: toggleTaskCompletion) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(task.isCompleted ? .green : .gray)
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                PriorityBadge(priority: task.priority)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        
                        Text(dueDate, style: .relative)
                            .font(.caption2)
                    }
                    .foregroundColor(dueDate < Date() ? .red : .secondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showingEditSheet = true
            }
        }
        .padding(12)
        .frame(width: 160, height: 120)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .contextMenu {
            Button(action: {
                showingEditSheet = true
            }) {
                Label("Edit Task", systemImage: "pencil")
            }
            
            Button(action: toggleTaskCompletion) {
                Label(task.isCompleted ? "Mark Incomplete" : "Mark Complete", 
                      systemImage: task.isCompleted ? "circle" : "checkmark.circle")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            TaskEditView(task: task) { updatedTask in
                onTaskUpdate(updatedTask)
            }
        }
    }
    
    private func toggleTaskCompletion() {
        let updatedTask = SimpleTaskItem(
            id: task.id,
            title: task.title,
            description: task.description,
            isCompleted: !task.isCompleted,
            priority: task.priority,
            dueDate: task.dueDate,
            createdAt: task.createdAt
        )
        onTaskUpdate(updatedTask)
    }
}

// MARK: - Detailed Task Row
struct DetailedTaskRow: View {
    let task: SimpleTaskItem
    let onNavigateToTasks: () -> Void
    let onTaskUpdate: (SimpleTaskItem) -> Void
    @State private var showingEditSheet = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: toggleTaskCompletion) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            
                            Text(dueDate, style: .relative)
                                .font(.caption2)
                        }
                        .foregroundColor(dueDate < Date() ? .red : .secondary)
                    }
                    
                    Spacer()
                    
                    PriorityBadge(priority: task.priority)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            showingEditSheet = true
        }
        .contextMenu {
            Button(action: {
                showingEditSheet = true
            }) {
                Label("Edit Task", systemImage: "pencil")
            }
            
            Button(action: toggleTaskCompletion) {
                Label(task.isCompleted ? "Mark Incomplete" : "Mark Complete", 
                      systemImage: task.isCompleted ? "circle" : "checkmark.circle")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            TaskEditView(task: task) { updatedTask in
                onTaskUpdate(updatedTask)
            }
        }
    }
    
    private func toggleTaskCompletion() {
        let updatedTask = SimpleTaskItem(
            id: task.id,
            title: task.title,
            description: task.description,
            isCompleted: !task.isCompleted,
            priority: task.priority,
            dueDate: task.dueDate,
            createdAt: task.createdAt
        )
        onTaskUpdate(updatedTask)
    }
}

// Add upcoming tasks to TaskManager
extension TaskManager {
    var upcomingTasks: [SimpleTaskItem] {
        let threeDaysFromNow = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        return tasks.filter { task in
            !task.isCompleted && (task.dueDate ?? .distantFuture) <= threeDaysFromNow
        }.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }
}

#Preview {
    MainContentView()
}