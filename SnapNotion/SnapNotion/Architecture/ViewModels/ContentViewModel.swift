//
//  ContentViewModel.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI
import Combine
import CoreData

// MARK: - Content View Model
@MainActor
class ContentViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var contentItems: [ContentItem] = []
    @Published var filteredItems: [ContentItem] = []
    @Published var searchText: String = ""
    @Published var selectedFilter: ContentFilter = .all
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let contentService: ContentServiceProtocol
    private let imageProcessor: ImageProcessorProtocol
    
    // MARK: - Initialization
    init(
        contentService: ContentServiceProtocol = SimpleContentService.shared,
        imageProcessor: ImageProcessorProtocol = ImageProcessor.shared
    ) {
        self.contentService = contentService
        self.imageProcessor = imageProcessor
        setupBindings()
        loadContent()
    }
    
    // MARK: - Public Methods
    func refreshContent() async {
        isLoading = true
        do {
            let items = try await contentService.fetchAllContent()
            self.contentItems = items
            applyFilters()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func toggleFavorite(for item: ContentItem) {
        Task {
            do {
                try await contentService.toggleFavorite(itemId: item.id)
                await refreshContent()
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteItem(_ item: ContentItem) {
        Task {
            do {
                try await contentService.deleteContent(itemId: item.id)
                await refreshContent()
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func processSharedContent(_ content: SharedContent) async {
        isLoading = true
        do {
            let processedItem = try await contentService.processSharedContent(content)
            contentItems.insert(processedItem, at: 0)
            applyFilters()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Search and filter binding
        Publishers.CombineLatest($searchText, $selectedFilter)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _, _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    private func applyFilters() {
        var filtered = contentItems
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.preview.localizedCaseInsensitiveContains(searchText) ||
                item.source.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply category filter
        switch selectedFilter {
        case .all:
            break
        case .favorites:
            filtered = filtered.filter { $0.isFavorite }
        case .images:
            filtered = filtered.filter { $0.type == .image || $0.type == .mixed }
        case .documents:
            filtered = filtered.filter { $0.type == .pdf || $0.type == .text }
        case .web:
            filtered = filtered.filter { $0.type == .web }
        case .bySource(let source):
            filtered = filtered.filter { $0.source == source.rawValue }
        }
        
        // Sort by timestamp (newest first)
        filtered.sort { $0.timestamp > $1.timestamp }
        
        filteredItems = filtered
    }
    
    private func loadContent() {
        Task {
            await refreshContent()
        }
    }
}

// MARK: - Content Filter Enum
enum ContentFilter: CaseIterable, Identifiable {
    case all
    case favorites
    case images
    case documents
    case web
    case bySource(AppSource)
    
    var id: String {
        switch self {
        case .all: return "all"
        case .favorites: return "favorites"
        case .images: return "images"
        case .documents: return "documents"
        case .web: return "web"
        case .bySource(let source): return "source_\(source.rawValue)"
        }
    }
    
    var displayName: String {
        switch self {
        case .all: return "全部"
        case .favorites: return "收藏"
        case .images: return "图片"
        case .documents: return "文档"
        case .web: return "网页"
        case .bySource(let source): return source.displayName
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "doc.on.doc"
        case .favorites: return "star.fill"
        case .images: return "photo"
        case .documents: return "doc.text"
        case .web: return "globe"
        case .bySource(let source): return source.icon
        }
    }
    
    static var allCases: [ContentFilter] {
        return [.all, .favorites, .images, .documents, .web]
    }
}

// SharedContent moved to SimpleModels.swift