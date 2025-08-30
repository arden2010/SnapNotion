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
    @Published var isLoadingMore: Bool = false
    @Published var hasMoreContent: Bool = true
    @Published var errorMessage: String?
    @Published var currentError: SnapNotionError?
    
    // MARK: - Pagination Properties
    private var currentPage: Int = 0
    private let pageSize: Int = 50
    private var isInitialLoad: Bool = true
    private var allContentLoaded: Bool = false
    
    // MARK: - Performance Properties
    private let contentCache = NSCache<NSString, NSArray>()
    private var backgroundQueue = DispatchQueue(label: "content.processing", qos: .userInitiated)
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let contentService: ContentServiceProtocol
    private let imageProcessor: ImageProcessorProtocol
    private let errorRecoveryManager = ErrorRecoveryManager.shared
    
    // MARK: - Initialization
    init(
        contentService: ContentServiceProtocol = SimpleContentService.shared,
        imageProcessor: ImageProcessorProtocol = ImageProcessor.shared
    ) {
        self.contentService = contentService
        self.imageProcessor = imageProcessor
        
        // Configure cache
        contentCache.countLimit = 200 // Cache up to 200 content items
        contentCache.totalCostLimit = 50 * 1024 * 1024 // 50MB cache limit
        
        setupBindings()
        loadInitialContent()
    }
    
    // MARK: - Content Loading Methods
    
    /// Load initial content with pagination
    func loadInitialContent() {
        guard !isLoading else { return }
        
        isLoading = true
        isInitialLoad = true
        currentPage = 0
        
        Task {
            await loadContentPage()
        }
    }
    
    /// Refresh content from the beginning
    func refreshContent() async {
        // Clear cache
        contentCache.removeAllObjects()
        allContentLoaded = false
        hasMoreContent = true
        currentPage = 0
        contentItems.removeAll()
        
        isLoading = true
        await loadContentPage()
    }
    
    /// Load more content (pagination)
    func loadMoreContent() {
        guard !isLoadingMore && hasMoreContent && !allContentLoaded else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        Task {
            await loadContentPage()
        }
    }
    
    private func loadContentPage() async {
        do {
            // Check cache first
            let cacheKey = "\(currentPage)_\(pageSize)_\(selectedFilter.id)" as NSString
            
            let newItems: [ContentItem]
            if let cachedItems = contentCache.object(forKey: cacheKey) as? [ContentItem] {
                newItems = cachedItems
                print("📱 Loaded \(newItems.count) items from cache")
            } else {
                // Fetch from service with pagination
                newItems = try await contentService.fetchContent(
                    page: currentPage,
                    pageSize: pageSize,
                    filter: selectedFilter,
                    searchQuery: searchText.isEmpty ? nil : searchText
                )
                
                // Cache the results
                contentCache.setObject(newItems as NSArray, forKey: cacheKey)
                print("📥 Loaded \(newItems.count) items from service")
            }
            
            // Update UI on main thread
            if isInitialLoad || currentPage == 0 {
                contentItems = newItems
                isInitialLoad = false
            } else {
                // Append new items, avoiding duplicates
                let existingIds = Set(contentItems.map { $0.id })
                let uniqueNewItems = newItems.filter { !existingIds.contains($0.id) }
                contentItems.append(contentsOf: uniqueNewItems)
            }
            
            // Update pagination state
            hasMoreContent = newItems.count == pageSize
            allContentLoaded = newItems.count < pageSize
            
            // Apply filters
            applyFilters()
            
        } catch let error as SnapNotionError {
            reportError(error, in: "ContentViewModel", operation: "loadContentPage", additionalInfo: ["page": currentPage])
        } catch {
            let snapNotionError = SnapNotionError.coreDataFetchFailed(entity: "ContentItem")
            reportError(snapNotionError, in: "ContentViewModel", operation: "loadContentPage", additionalInfo: ["underlyingError": error.localizedDescription])
        }
        
        isLoading = false
        isLoadingMore = false
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
    
    // MARK: - Computed Properties
    var recentItems: [ContentItem] {
        return contentItems.prefix(10).map { $0 }
    }
    
    var recentItemsCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return contentItems.filter { $0.timestamp > weekAgo }.count
    }
    
    var favoriteItemsCount: Int {
        return contentItems.filter { $0.isFavorite }.count
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
// ContentFilter moved to SimpleModels.swift

// SharedContent moved to SimpleModels.swift