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
            
            // Floating Action Button (same position as Inbox tab)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingAddSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .frame(width: 56, height: 56)
                    .background(Color.phoenixOrange)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddContentSheet()
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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No documents yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.filteredItems) { item in
                            ContentRowView(
                                item: item,
                                onFavoriteToggle: {
                                    viewModel.toggleFavorite(for: item)
                                },
                                onDelete: {
                                    viewModel.deleteItem(item)
                                }
                            )
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Library")
            .onAppear {
                // Load library content
            }
        }
    }
}

// MARK: - Favorites Content View
struct FavoritesContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredItems.filter({ $0.isFavorite }).isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No favorites yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("Items you favorite will appear here")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.filteredItems.filter({ $0.isFavorite })) { item in
                            ContentRowView(
                                item: item,
                                onFavoriteToggle: {
                                    viewModel.toggleFavorite(for: item)
                                },
                                onDelete: {
                                    viewModel.deleteItem(item)
                                }
                            )
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Favorites")
            .onAppear {
                // Load favorites
            }
        }
    }
}

// MARK: - Tasks Content View
struct TasksContentView: View {
    @StateObject private var taskManager = TaskManager()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if taskManager.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if taskManager.tasks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No tasks yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("Tasks will be generated from your content")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(taskManager.tasks) { task in
                            TaskRowView(task: task) { updatedTask in
                                taskManager.updateTask(updatedTask)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Tasks")
            .onAppear {
                // Load tasks
            }
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

#Preview {
    ContentTypesView()
}