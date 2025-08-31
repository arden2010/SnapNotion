//
//  ContentTypesView.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI

struct ContentTypesView: View {
    @State private var selectedType: ContentTypeCategory = .library
    @State private var showingAddSheet = false
    @State private var showingOptionsMenu = false
    @StateObject private var clipboardMonitor = ClipboardMonitor()
    private let contentProcessor = ContentCaptureProcessor.shared
    @State private var showingProcessing = false
    @State private var processingMessage = ""
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Content area
                Group {
                    switch selectedType {
                    case .library:
                        LibraryContentView()
                    case .favorites:
                        FavoritesContentView()
                    case .tasks:
                        TasksContentView()
                    }
                }
                
                // Compact 3-tab bottom bar (closer together, leaving space for FAB)
                HStack(spacing: 0) {
                    // Left side tabs (compact)
                    HStack(spacing: 12) {
                        ForEach(ContentTypeCategory.allCases, id: \.self) { type in
                            Button(action: {
                                selectedType = type
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: selectedType == type ? type.activeIcon : type.icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(selectedType == type ? .phoenixOrange : .secondary)
                                    
                                    Text(type.title)
                                        .font(.caption)
                                        .foregroundColor(selectedType == type ? .phoenixOrange : .secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                }
                .background(Color(.systemBackground))
                .overlay(
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 0.5),
                    alignment: .top
                )
            }
            
            // Smart Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    SmartFloatingActionButton(
                        onPaste: {
                            handlePasteAction()
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
        .sheet(isPresented: $showingAddSheet) {
            AddContentSheet()
        }
        .sheet(isPresented: $showingOptionsMenu) {
            ContentOptionsMenu()
        }
        .overlay {
            if showingProcessing {
                ProcessingOverlay(message: processingMessage)
            }
        }
    }
    
    // MARK: - Actions
    private func handlePasteAction() {
        guard let clipboardContent = clipboardMonitor.getClipboardContent() else {
            return
        }
        
        Task {
            await MainActor.run {
                showingProcessing = true
                processingMessage = "📋 Processing clipboard content..."
            }
            
            do {
                let result: ContentItem
                
                switch clipboardContent.type {
                case .text:
                    if let text = clipboardContent.text {
                        result = try await contentProcessor.processText(text, source: "Smart FAB")
                    } else {
                        throw ContentProcessingError.aiProcessingFailed
                    }
                    
                case .image:
                    if let imageData = clipboardContent.data {
                        result = try await contentProcessor.processImage(imageData, source: "Smart FAB")
                    } else {
                        throw ContentProcessingError.imageConversionFailed
                    }
                    
                case .web:
                    if let url = clipboardContent.url {
                        result = try await contentProcessor.processWebURL(url, source: "Smart FAB")
                    } else {
                        throw ContentProcessingError.aiProcessingFailed
                    }
                    
                case .mixed, .pdf:
                    if let text = clipboardContent.text {
                        result = try await contentProcessor.processText(text, source: "Smart FAB")
                    } else {
                        throw ContentProcessingError.aiProcessingFailed
                    }
                }
                
                await MainActor.run {
                    processingMessage = "✅ Content processed successfully!"
                    
                    // Brief success message then dismiss
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.showingProcessing = false
                    }
                }
                
            } catch {
                await MainActor.run {
                    processingMessage = "❌ Failed to process: \(error.localizedDescription)"
                    
                    // Show error for a moment then dismiss
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.showingProcessing = false
                    }
                }
            }
        }
    }
}

enum ContentTypeCategory: String, CaseIterable {
    case library = "library"
    case favorites = "favorites"
    case tasks = "tasks"
    
    var title: String {
        switch self {
        case .library: return "Library"
        case .favorites: return "Favorites"
        case .tasks: return "Tasks"
        }
    }
    
    var icon: String {
        switch self {
        case .library: return "books.vertical"
        case .favorites: return "heart"
        case .tasks: return "checkmark.circle"
        }
    }
    
    var activeIcon: String {
        switch self {
        case .library: return "books.vertical.fill"
        case .favorites: return "heart.fill"
        case .tasks: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Library Content View
struct LibraryContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var selectedViewStyle: ContentViewStyle = .standard
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar - positioned at top for easy thumb access
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                        
                        TextField("Search by text, tags, or meaning...", text: $searchText)
                            .textFieldStyle(.plain)
                            .onTapGesture {
                                isSearching = true
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                isSearching = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    if isSearching {
                        Button("Cancel") {
                            searchText = ""
                            isSearching = false
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        .font(.system(size: 16))
                        .foregroundColor(.phoenixOrange)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                Divider()
                
                // Content Area
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredLibraryItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: searchText.isEmpty ? "doc.text" : "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text(searchText.isEmpty ? "No documents yet" : "No results found")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        if !searchText.isEmpty {
                            Text("Try different search terms")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // View Content Based on Selected Style
                    Group {
                        switch selectedViewStyle {
                        case .standard:
                            List {
                                ForEach(filteredLibraryItems) { item in
                                    ContentRowView(
                                        item: item,
                                        onFavoriteToggle: { viewModel.toggleFavorite(for: item) },
                                        onDelete: { viewModel.deleteItem(item) }
                                    )
                                    .contextMenu {
                                        ContentContextMenu(
                                            item: item,
                                            onFavoriteToggle: { viewModel.toggleFavorite(for: item) },
                                            onEdit: { /* Handle edit */ },
                                            onShare: { /* Handle share */ },
                                            onDelete: { viewModel.deleteItem(item) }
                                        )
                                    }
                                }
                            }
                            .listStyle(PlainListStyle())
                            
                        case .compact:
                            List {
                                ForEach(filteredLibraryItems) { item in
                                    CompactContentRowView(
                                        item: item,
                                        onFavoriteToggle: { viewModel.toggleFavorite(for: item) },
                                        onDelete: { viewModel.deleteItem(item) }
                                    )
                                    .contextMenu {
                                        ContentContextMenu(
                                            item: item,
                                            onFavoriteToggle: { viewModel.toggleFavorite(for: item) },
                                            onEdit: { /* Handle edit */ },
                                            onShare: { /* Handle share */ },
                                            onDelete: { viewModel.deleteItem(item) }
                                        )
                                    }
                                }
                            }
                            .listStyle(PlainListStyle())
                            
                        case .detailed:
                            List {
                                ForEach(filteredLibraryItems) { item in
                                    DetailedContentRowView(
                                        item: item,
                                        onFavoriteToggle: { viewModel.toggleFavorite(for: item) },
                                        onDelete: { viewModel.deleteItem(item) }
                                    )
                                    .contextMenu {
                                        ContentContextMenu(
                                            item: item,
                                            onFavoriteToggle: { viewModel.toggleFavorite(for: item) },
                                            onEdit: { /* Handle edit */ },
                                            onShare: { /* Handle share */ },
                                            onDelete: { viewModel.deleteItem(item) }
                                        )
                                    }
                                }
                            }
                            .listStyle(PlainListStyle())
                            
                        case .grid:
                            ScrollView {
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ], spacing: 12) {
                                    ForEach(filteredLibraryItems) { item in
                                        GridContentCard(item: item)
                                            .contextMenu {
                                                ContentContextMenu(
                                                    item: item,
                                                    onFavoriteToggle: { viewModel.toggleFavorite(for: item) },
                                                    onEdit: { /* Handle edit */ },
                                                    onShare: { /* Handle share */ },
                                                    onDelete: { viewModel.deleteItem(item) }
                                                )
                                            }
                                    }
                                }
                                .padding()
                                
                                Spacer(minLength: 100) // Space for FAB
                            }
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        // View Style Buttons (same as Inbox)
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
            .onChange(of: searchText) { newValue in
                viewModel.searchText = newValue
            }
            .onAppear {
                // Load all content for library
            }
        }
    }
    
    // Computed property for filtered library items
    private var filteredLibraryItems: [ContentItem] {
        var items = viewModel.contentItems
        
        // Apply search filter if search text exists
        if !searchText.isEmpty {
            items = items.filter { item in
                // Search by text content
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.preview.localizedCaseInsensitiveContains(searchText) ||
                item.source.localizedCaseInsensitiveContains(searchText) ||
                // TODO: Add tag search when tags are implemented
                // item.tags.contains { $0.localizedCaseInsensitiveContains(searchText) } ||
                // TODO: Add semantic meaning search when AI features are implemented
                item.type.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort by timestamp (newest first)
        return items.sorted { $0.timestamp > $1.timestamp }
    }
}

// MARK: - Favorites Content View
struct FavoritesContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var selectedViewStyle: ContentViewStyle = .standard
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar - positioned at top for easy thumb access
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                        
                        TextField("Search favorites...", text: $searchText)
                            .textFieldStyle(.plain)
                            .onTapGesture {
                                isSearching = true
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                isSearching = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    if isSearching {
                        Button("Cancel") {
                            searchText = ""
                            isSearching = false
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        .font(.system(size: 16))
                        .foregroundColor(.phoenixOrange)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                Divider()
                
                // Content Area
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredFavoriteItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: searchText.isEmpty ? "heart" : "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text(searchText.isEmpty ? "No favorites yet" : "No results found")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        if searchText.isEmpty {
                            Text("Items you favorite will appear here")
                                .font(.body)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Try different search terms")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // View Content Based on Selected Style
                    Group {
                        switch selectedViewStyle {
                        case .standard:
                            List {
                                ForEach(filteredFavoriteItems) { item in
                                    ContentRowView(
                                        item: item,
                                        onFavoriteToggle: { viewModel.toggleFavorite(for: item) },
                                        onDelete: { viewModel.deleteItem(item) }
                                    )
                                    .contextMenu {
                                        ContentContextMenu(
                                            item: item,
                                            onFavoriteToggle: { viewModel.toggleFavorite(for: item) },
                                            onEdit: { /* Handle edit */ },
                                            onShare: { /* Handle share */ },
                                            onDelete: { viewModel.deleteItem(item) }
                                        )
                                    }
                                }
                            }
                            .listStyle(PlainListStyle())
                            
                        case .compact:
                            List {
                                ForEach(filteredFavoriteItems) { item in
                                    CompactContentRowView(
                                        item: item,
                                        onFavoriteToggle: { viewModel.toggleFavorite(for: item) },
                                        onDelete: { viewModel.deleteItem(item) }
                                    )
                                    .contextMenu {
                                        ContentContextMenu(
                                            item: item,
                                            onFavoriteToggle: { viewModel.toggleFavorite(for: item) },
                                            onEdit: { /* Handle edit */ },
                                            onShare: { /* Handle share */ },
                                            onDelete: { viewModel.deleteItem(item) }
                                        )
                                    }
                                }
                            }
                            .listStyle(PlainListStyle())
                            
                        case .detailed:
                            List {
                                ForEach(filteredFavoriteItems) { item in
                                    DetailedContentRowView(
                                        item: item,
                                        onFavoriteToggle: { viewModel.toggleFavorite(for: item) },
                                        onDelete: { viewModel.deleteItem(item) }
                                    )
                                    .contextMenu {
                                        ContentContextMenu(
                                            item: item,
                                            onFavoriteToggle: { viewModel.toggleFavorite(for: item) },
                                            onEdit: { /* Handle edit */ },
                                            onShare: { /* Handle share */ },
                                            onDelete: { viewModel.deleteItem(item) }
                                        )
                                    }
                                }
                            }
                            .listStyle(PlainListStyle())
                            
                        case .grid:
                            ScrollView {
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ], spacing: 12) {
                                    ForEach(filteredFavoriteItems) { item in
                                        GridContentCard(item: item)
                                            .contextMenu {
                                                ContentContextMenu(
                                                    item: item,
                                                    onFavoriteToggle: { viewModel.toggleFavorite(for: item) },
                                                    onEdit: { /* Handle edit */ },
                                                    onShare: { /* Handle share */ },
                                                    onDelete: { viewModel.deleteItem(item) }
                                                )
                                            }
                                    }
                                }
                                .padding()
                                
                                Spacer(minLength: 100) // Space for FAB
                            }
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
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
            .onAppear {
                // Load favorites
            }
        }
    }
    
    // Computed property for filtered favorite items
    private var filteredFavoriteItems: [ContentItem] {
        var items = viewModel.contentItems.filter { $0.isFavorite }
        
        // Apply search filter if search text exists
        if !searchText.isEmpty {
            items = items.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.preview.localizedCaseInsensitiveContains(searchText) ||
                item.source.localizedCaseInsensitiveContains(searchText) ||
                item.type.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort by timestamp (newest first)
        return items.sorted { $0.timestamp > $1.timestamp }
    }
}

// MARK: - Tasks Content View
struct TasksContentView: View {
    @StateObject private var taskManager = TaskManager()
    @State private var selectedViewStyle: TaskViewStyle = .standard
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar - positioned at top for easy thumb access
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                        
                        TextField("Search tasks...", text: $searchText)
                            .textFieldStyle(.plain)
                            .onTapGesture {
                                isSearching = true
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                isSearching = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    if isSearching {
                        Button("Cancel") {
                            searchText = ""
                            isSearching = false
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        .font(.system(size: 16))
                        .foregroundColor(.phoenixOrange)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                Divider()
                
                // Content Area
                if taskManager.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredTasks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: searchText.isEmpty ? "checkmark.circle" : "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text(searchText.isEmpty ? "No tasks yet" : "No results found")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        if searchText.isEmpty {
                            Text("Tasks will be generated from your content")
                                .font(.body)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Try different search terms")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // View Tasks Based on Selected Style
                    Group {
                        switch selectedViewStyle {
                        case .standard:
                            List {
                                ForEach(filteredTasks) { task in
                                    TaskRowView(task: task) { updatedTask in
                                        taskManager.updateTask(updatedTask)
                                    }
                                }
                            }
                            .listStyle(PlainListStyle())
                            
                        case .compact:
                            List {
                                ForEach(filteredTasks) { task in
                                    CompactTaskRowView(task: task) { updatedTask in
                                        taskManager.updateTask(updatedTask)
                                    }
                                }
                            }
                            .listStyle(PlainListStyle())
                            
                        case .detailed:
                            List {
                                ForEach(filteredTasks) { task in
                                    DetailedTaskRowView(task: task) { updatedTask in
                                        taskManager.updateTask(updatedTask)
                                    }
                                }
                            }
                            .listStyle(PlainListStyle())
                            
                        case .byPriority:
                            List {
                                ForEach(groupedTasksByPriority, id: \.priority) { group in
                                    Section(group.priority.displayName) {
                                        ForEach(group.tasks) { task in
                                            TaskRowView(task: task) { updatedTask in
                                                taskManager.updateTask(updatedTask)
                                            }
                                        }
                                    }
                                }
                            }
                            .listStyle(InsetGroupedListStyle())
                        }
                    }
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        // Task View Style Buttons
                        ForEach(TaskViewStyle.allCases, id: \.self) { style in
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
            .onAppear {
                // Load tasks
            }
        }
    }
    
    // Computed property for filtered tasks
    private var filteredTasks: [SimpleTaskItem] {
        var tasks = taskManager.tasks
        
        // Apply search filter if search text exists
        if !searchText.isEmpty {
            tasks = tasks.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                task.description.localizedCaseInsensitiveContains(searchText) ||
                task.priority.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort by priority and due date
        return tasks.sorted { task1, task2 in
            if task1.priority != task2.priority {
                return task1.priority.sortOrder < task2.priority.sortOrder
            }
            return (task1.dueDate ?? .distantFuture) < (task2.dueDate ?? .distantFuture)
        }
    }
    
    // Grouped tasks by priority
    private var groupedTasksByPriority: [TaskPriorityGroup] {
        let grouped = Dictionary(grouping: filteredTasks) { $0.priority }
        return SimpleTaskItem.TaskPriority.allCases.compactMap { priority in
            guard let tasks = grouped[priority], !tasks.isEmpty else { return nil }
            return TaskPriorityGroup(priority: priority, tasks: tasks.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) })
        }
    }
    
    // Grouped tasks by status
    private var groupedTasksByStatus: [TaskStatusGroup] {
        let grouped = Dictionary(grouping: filteredTasks) { $0.isCompleted ? "Completed" : "Active" }
        return ["Active", "Completed"].compactMap { status in
            guard let tasks = grouped[status], !tasks.isEmpty else { return nil }
            return TaskStatusGroup(status: status, tasks: tasks)
        }
    }
}


// MARK: - Simple Task Manager
class TaskManager: ObservableObject {
    @Published var tasks: [SimpleTaskItem] = SimpleTaskItem.sampleTasks
    @Published var isLoading = false
    
    func toggleComplete(_ task: SimpleTaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
        }
    }
    
    func updateTask(_ updatedTask: SimpleTaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
            tasks[index] = updatedTask
        }
    }
    
    func addSampleTask() {
        let newTask = SimpleTaskItem(
            title: "New Task",
            description: "Generated from content analysis",
            isCompleted: false,
            priority: .medium,
            dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
        )
        tasks.insert(newTask, at: 0)
    }
}

// MARK: - Task View Styles
enum TaskViewStyle: String, CaseIterable {
    case standard = "standard"
    case compact = "compact"
    case detailed = "detailed"
    case byPriority = "byPriority"
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .compact: return "Compact"
        case .detailed: return "Detailed"
        case .byPriority: return "By Priority"
        }
    }
    
    var icon: String {
        switch self {
        case .standard: return "list.bullet"
        case .compact: return "list.dash"
        case .detailed: return "list.bullet.rectangle"
        case .byPriority: return "exclamationmark.triangle"
        }
    }
}

// MARK: - Supporting Task Types
struct TaskPriorityGroup {
    let priority: SimpleTaskItem.TaskPriority
    let tasks: [SimpleTaskItem]
}

struct TaskStatusGroup {
    let status: String
    let tasks: [SimpleTaskItem]
}

// MARK: - Compact Task Row View
struct CompactTaskRowView: View {
    let task: SimpleTaskItem
    let onTaskUpdate: (SimpleTaskItem) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                var updatedTask = task
                updatedTask.isCompleted.toggle()
                onTaskUpdate(updatedTask)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                    .lineLimit(1)
                
                if let dueDate = task.dueDate {
                    Text(dueDate, style: .relative)
                        .font(.caption2)
                        .foregroundColor(dueDate < Date() ? .red : .secondary)
                }
            }
            
            Spacer()
            
            Circle()
                .fill(task.priority.color)
                .frame(width: 6, height: 6)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Detailed Task Row View
struct DetailedTaskRowView: View {
    let task: SimpleTaskItem
    let onTaskUpdate: (SimpleTaskItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 12) {
                    Button(action: {
                        var updatedTask = task
                        updatedTask.isCompleted.toggle()
                        onTaskUpdate(updatedTask)
                    }) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(task.isCompleted ? .green : .gray)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .strikethrough(task.isCompleted)
                        
                        Text("Created \(task.createdAt, style: .relative)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    PriorityBadge(priority: task.priority)
                    
                    if let dueDate = task.dueDate {
                        Text(dueDate, style: .relative)
                            .font(.caption)
                            .foregroundColor(dueDate < Date() ? .red : .secondary)
                    }
                }
            }
            
            if !task.description.isEmpty {
                Text(task.description)
                    .font(.body)
                    .lineLimit(3)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        
                        Text("Due \(dueDate, style: .relative)")
                            .font(.caption2)
                    }
                    .foregroundColor(dueDate < Date() ? .red : .secondary)
                }
                
                Spacer()
                
                Text(task.isCompleted ? "Completed" : "Active")
                    .font(.caption2)
                    .foregroundColor(task.isCompleted ? .green : .orange)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Task Priority Extensions
extension SimpleTaskItem.TaskPriority {
    var sortOrder: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
}

#Preview {
    ContentTypesView()
}