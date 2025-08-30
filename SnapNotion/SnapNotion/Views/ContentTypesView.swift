//
//  ContentTypesView.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI

struct ContentTypesView: View {
    @State private var selectedType: ContentTypeCategory = .library
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Type selector
                Picker("Content Type", selection: $selectedType) {
                    ForEach(ContentTypeCategory.allCases, id: \.self) { type in
                        Text(type.title).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected type
                switch selectedType {
                case .library:
                    LibraryContentView()
                case .favorites:
                    FavoritesContentView()
                case .tasks:
                    TasksContentView()
                }
            }
            .navigationTitle("Content Types")
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
}

// MARK: - Library Content View
struct LibraryContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
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
        .onAppear {
            // Load library content
        }
    }
}

// MARK: - Favorites Content View
struct FavoritesContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
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
        .onAppear {
            // Load favorites
        }
    }
}

// MARK: - Tasks Content View
struct TasksContentView: View {
    @StateObject private var taskManager = TaskManager()
    
    var body: some View {
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
        .onAppear {
            // Load tasks
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
}

#Preview {
    ContentTypesView()
}