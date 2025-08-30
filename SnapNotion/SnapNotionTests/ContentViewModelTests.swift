//
//  ContentViewModelTests.swift
//  SnapNotionTests
//
//  Created by A. C. on 8/30/25.
//

import XCTest
import Combine
@testable import SnapNotion

@MainActor
final class ContentViewModelTests: XCTestCase {
    
    var viewModel: ContentViewModel!
    var mockContentService: MockContentService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        super.setUp()
        mockContentService = MockContentService()
        viewModel = ContentViewModel(contentService: mockContentService, imageProcessor: MockImageProcessor())
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        mockContentService = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Content Loading Tests
    
    func testInitialContentLoading() async {
        // Given
        let expectedItems = createMockContentItems(count: 5)
        mockContentService.mockItems = expectedItems
        
        // When
        await viewModel.refreshContent()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.contentItems.count, 5)
        XCTAssertEqual(viewModel.filteredItems.count, 5)
    }
    
    func testPaginationLoading() async {
        // Given
        let page1Items = createMockContentItems(count: 50, startId: 1)
        let page2Items = createMockContentItems(count: 25, startId: 51)
        
        mockContentService.mockItems = page1Items
        
        // When - Load first page
        await viewModel.refreshContent()
        
        // Then
        XCTAssertEqual(viewModel.contentItems.count, 50)
        XCTAssertTrue(viewModel.hasMoreContent)
        
        // When - Load second page
        mockContentService.mockItems = page2Items
        viewModel.loadMoreContent()
        
        // Wait for loading to complete
        let expectation = expectation(description: "Load more completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
        
        // Then
        XCTAssertEqual(viewModel.contentItems.count, 75)
        XCTAssertFalse(viewModel.hasMoreContent) // Less than page size indicates end
    }
    
    func testRefreshContent() async {
        // Given
        viewModel.contentItems = createMockContentItems(count: 5)
        let newItems = createMockContentItems(count: 3)
        mockContentService.mockItems = newItems
        
        // When
        await viewModel.refreshContent()
        
        // Then
        XCTAssertEqual(viewModel.contentItems.count, 3) // Replaced, not appended
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Search and Filter Tests
    
    func testSearchFiltering() {
        // Given
        let items = [
            ContentItem(id: UUID(), type: .text, title: "Swift Programming", preview: "Learning Swift", timestamp: Date(), source: "book", isFavorite: false),
            ContentItem(id: UUID(), type: .text, title: "Python Tutorial", preview: "Python basics", timestamp: Date(), source: "web", isFavorite: false),
            ContentItem(id: UUID(), type: .text, title: "SwiftUI Guide", preview: "Building UIs", timestamp: Date(), source: "documentation", isFavorite: false)
        ]
        viewModel.contentItems = items
        
        // When
        viewModel.searchText = "Swift"
        
        // Wait for debounce
        let expectation = expectation(description: "Search applied")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertEqual(viewModel.filteredItems.count, 2)
        XCTAssertTrue(viewModel.filteredItems.allSatisfy { $0.title.contains("Swift") || $0.preview.contains("Swift") })
    }
    
    func testCategoryFiltering() {
        // Given
        let items = [
            ContentItem(id: UUID(), type: .text, title: "Text 1", preview: "Preview", timestamp: Date(), source: "source", isFavorite: false),
            ContentItem(id: UUID(), type: .image, title: "Image 1", preview: "Preview", timestamp: Date(), source: "source", isFavorite: false),
            ContentItem(id: UUID(), type: .web, title: "Web 1", preview: "Preview", timestamp: Date(), source: "source", isFavorite: false),
            ContentItem(id: UUID(), type: .text, title: "Text 2", preview: "Preview", timestamp: Date(), source: "source", isFavorite: true)
        ]
        viewModel.contentItems = items
        
        // When - Filter by favorites
        viewModel.selectedFilter = .favorites
        
        // Then
        XCTAssertEqual(viewModel.filteredItems.count, 1)
        XCTAssertTrue(viewModel.filteredItems.first?.isFavorite == true)
        
        // When - Filter by images
        viewModel.selectedFilter = .images
        
        // Then
        XCTAssertEqual(viewModel.filteredItems.count, 1)
        XCTAssertEqual(viewModel.filteredItems.first?.type, .image)
    }
    
    // MARK: - Content Actions Tests
    
    func testToggleFavorite() async {
        // Given
        let item = ContentItem(id: UUID(), type: .text, title: "Test", preview: "Preview", timestamp: Date(), source: "source", isFavorite: false)
        mockContentService.mockItems = [item]
        await viewModel.refreshContent()
        
        // When
        viewModel.toggleFavorite(for: item)
        
        // Wait for async operation
        let expectation = expectation(description: "Favorite toggled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
        
        // Then
        XCTAssertTrue(mockContentService.toggleFavoriteCalled)
    }
    
    func testDeleteItem() async {
        // Given
        let item = ContentItem(id: UUID(), type: .text, title: "Test", preview: "Preview", timestamp: Date(), source: "source", isFavorite: false)
        mockContentService.mockItems = [item]
        await viewModel.refreshContent()
        
        // When
        viewModel.deleteItem(item)
        
        // Wait for async operation
        let expectation = expectation(description: "Item deleted")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
        
        // Then
        XCTAssertTrue(mockContentService.deleteContentCalled)
    }
    
    // MARK: - Error Handling Tests
    
    func testContentLoadingError() async {
        // Given
        mockContentService.shouldFailFetch = true
        
        // When
        await viewModel.refreshContent()
        
        // Then
        XCTAssertNotNil(viewModel.currentError)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Performance Tests
    
    func testLargeDatasetPerformance() async {
        // Given
        let largeDataset = createMockContentItems(count: 1000)
        mockContentService.mockItems = largeDataset
        
        // When
        let startTime = Date()
        await viewModel.refreshContent()
        let endTime = Date()
        
        // Then
        let processingTime = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(processingTime, 1.0, "Should process 1000 items in under 1 second")
        XCTAssertEqual(viewModel.contentItems.count, 1000)
    }
    
    func testSearchPerformance() {
        // Given
        let largeDataset = createMockContentItems(count: 1000)
        viewModel.contentItems = largeDataset
        
        // When/Then
        measure {
            viewModel.searchText = "test search query"
            // Apply filters immediately for performance test
            viewModel.applyFilters()
        }
    }
    
    // MARK: - Computed Properties Tests
    
    func testRecentItems() {
        // Given
        let oldItem = ContentItem(id: UUID(), type: .text, title: "Old", preview: "Preview", timestamp: Date().addingTimeInterval(-86400), source: "source", isFavorite: false)
        let recentItem = ContentItem(id: UUID(), type: .text, title: "Recent", preview: "Preview", timestamp: Date(), source: "source", isFavorite: false)
        
        viewModel.contentItems = [oldItem, recentItem]
        
        // When
        let recent = viewModel.recentItems
        
        // Then
        XCTAssertEqual(recent.count, 2)
        XCTAssertEqual(recent.first?.title, "Recent") // Should be sorted by timestamp
    }
    
    func testRecentItemsCount() {
        // Given
        let weekOldItem = ContentItem(id: UUID(), type: .text, title: "Week Old", preview: "Preview", timestamp: Date().addingTimeInterval(-8*24*3600), source: "source", isFavorite: false)
        let recentItem = ContentItem(id: UUID(), type: .text, title: "Recent", preview: "Preview", timestamp: Date(), source: "source", isFavorite: false)
        
        viewModel.contentItems = [weekOldItem, recentItem]
        
        // When
        let recentCount = viewModel.recentItemsCount
        
        // Then
        XCTAssertEqual(recentCount, 1) // Only recent item within 7 days
    }
    
    func testFavoriteItemsCount() {
        // Given
        let items = [
            ContentItem(id: UUID(), type: .text, title: "Fav 1", preview: "Preview", timestamp: Date(), source: "source", isFavorite: true),
            ContentItem(id: UUID(), type: .text, title: "Normal 1", preview: "Preview", timestamp: Date(), source: "source", isFavorite: false),
            ContentItem(id: UUID(), type: .text, title: "Fav 2", preview: "Preview", timestamp: Date(), source: "source", isFavorite: true)
        ]
        viewModel.contentItems = items
        
        // When
        let favoriteCount = viewModel.favoriteItemsCount
        
        // Then
        XCTAssertEqual(favoriteCount, 2)
    }
    
    // MARK: - Helper Methods
    
    private func createMockContentItems(count: Int, startId: Int = 1) -> [ContentItem] {
        return (startId..<startId + count).map { i in
            ContentItem(
                id: UUID(),
                type: .text,
                title: "Item \(i)",
                preview: "Preview \(i)",
                timestamp: Date().addingTimeInterval(-Double(i * 60)),
                source: "source",
                isFavorite: i % 3 == 0
            )
        }
    }
}

// MARK: - Mock Services

class MockImageProcessor: ImageProcessorProtocol {
    func processImage(_ imageData: Data) async throws -> ProcessedImageResult {
        return ProcessedImageResult(
            originalData: imageData,
            thumbnailData: imageData,
            extractedText: "Mock extracted text",
            confidence: 0.95,
            metadata: ["mock": true]
        )
    }
}

extension MockContentService {
    var mockItems: [ContentItem] = []
    var shouldFailFetch = false
    var toggleFavoriteCalled = false
    var deleteContentCalled = false
    
    override func fetchContent(page: Int, pageSize: Int, filter: ContentFilter, searchQuery: String?) async throws -> [ContentItem] {
        if shouldFailFetch {
            throw SnapNotionError.networkConnectionFailed
        }
        
        // Simulate pagination
        let startIndex = page * pageSize
        let endIndex = min(startIndex + pageSize, mockItems.count)
        
        guard startIndex < mockItems.count else {
            return []
        }
        
        return Array(mockItems[startIndex..<endIndex])
    }
    
    override func toggleFavorite(itemId: UUID) async throws {
        toggleFavoriteCalled = true
    }
    
    override func deleteContent(itemId: UUID) async throws {
        deleteContentCalled = true
    }
}