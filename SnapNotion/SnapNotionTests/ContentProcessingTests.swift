//
//  ContentProcessingTests.swift
//  SnapNotionTests
//
//  Created by A. C. on 8/30/25.
//

import XCTest
import CoreData
@testable import SnapNotion

final class ContentProcessingTests: XCTestCase {
    
    var contentProcessor: ContentProcessingPipeline!
    var testContext: NSManagedObjectContext!
    var persistenceController: PersistenceController!
    
    override func setUpWithError() throws {
        super.setUp()
        
        // Create in-memory Core Data stack for testing
        persistenceController = PersistenceController(inMemory: true)
        testContext = persistenceController.container.viewContext
        
        // Initialize content processor with test context
        contentProcessor = ContentProcessingPipeline.shared
    }
    
    override func tearDownWithError() throws {
        contentProcessor = nil
        testContext = nil
        persistenceController = nil
        super.tearDown()
    }
    
    // MARK: - Text Content Processing Tests
    
    func testTextContentProcessing() async throws {
        // Given
        let testText = "This is a sample text for testing content processing capabilities."
        let sharedContent = SharedContent(
            type: .text,
            data: testText.data(using: .utf8),
            text: testText,
            url: nil,
            sourceApp: .other,
            metadata: ["test": true]
        )
        
        // When
        let processedContent = try await contentProcessor.processContent(sharedContent)
        
        // Then
        XCTAssertEqual(processedContent.title, "Sample text for testing")
        XCTAssertEqual(processedContent.contentText, testText)
        XCTAssertEqual(processedContent.contentType, "text")
        XCTAssertEqual(processedContent.sourceApp, "other")
        XCTAssertNotNil(processedContent.createdAt)
    }
    
    func testURLContentProcessing() async throws {
        // Given
        let testURL = "https://www.example.com/test-article"
        let sharedContent = SharedContent(
            type: .url,
            data: testURL.data(using: .utf8),
            text: testURL,
            url: testURL,
            sourceApp: .safari,
            metadata: ["domain": "example.com"]
        )
        
        // When
        let processedContent = try await contentProcessor.processContent(sharedContent)
        
        // Then
        XCTAssertTrue(processedContent.title.contains("example.com"))
        XCTAssertEqual(processedContent.sourceURL, testURL)
        XCTAssertEqual(processedContent.contentType, "url")
        XCTAssertEqual(processedContent.sourceApp, "safari")
    }
    
    func testImageContentProcessing() async throws {
        // Given
        let testImageData = createTestImageData()
        let sharedContent = SharedContent(
            type: .image,
            data: testImageData,
            text: nil,
            url: nil,
            sourceApp: .camera,
            metadata: ["imageSize": "100x100"]
        )
        
        // When
        let processedContent = try await contentProcessor.processContent(sharedContent)
        
        // Then
        XCTAssertEqual(processedContent.contentType, "image")
        XCTAssertEqual(processedContent.sourceApp, "camera")
        XCTAssertNotNil(processedContent.contentData)
        XCTAssertTrue(processedContent.title.contains("Image"))
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidContentProcessing() async {
        // Given
        let invalidContent = SharedContent(
            type: .text,
            data: nil,
            text: nil,
            url: nil,
            sourceApp: .other,
            metadata: [:]
        )
        
        // When/Then
        do {
            _ = try await contentProcessor.processContent(invalidContent)
            XCTFail("Should throw error for invalid content")
        } catch let error as SnapNotionError {
            switch error {
            case .contentProcessingFailed:
                XCTAssertTrue(true, "Correctly threw content processing error")
            default:
                XCTFail("Wrong error type thrown: \(error)")
            }
        } catch {
            XCTFail("Wrong error type thrown: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testContentProcessingPerformance() {
        let testText = String(repeating: "Performance test content. ", count: 1000)
        let sharedContent = SharedContent(
            type: .text,
            data: testText.data(using: .utf8),
            text: testText,
            url: nil,
            sourceApp: .other,
            metadata: [:]
        )
        
        measure {
            Task {
                _ = try? await contentProcessor.processContent(sharedContent)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestImageData() -> Data {
        // Create a simple 1x1 pixel PNG for testing
        let image = UIImage(systemName: "photo")!
        return image.jpegData(compressionQuality: 0.5) ?? Data()
    }
}

// MARK: - Mock Content Service for Testing

class MockContentService: ContentServiceProtocol {
    var shouldFailProcessing = false
    var processedContents: [SharedContent] = []
    
    func fetchContent(page: Int, pageSize: Int, filter: ContentFilter, searchQuery: String?) async throws -> [ContentItem] {
        return []
    }
    
    func processSharedContent(_ content: SharedContent) async throws -> ContentItem {
        if shouldFailProcessing {
            throw SnapNotionError.contentProcessingFailed(underlying: "Mock failure")
        }
        
        processedContents.append(content)
        
        return ContentItem(
            id: UUID(),
            type: content.type,
            title: "Mock Title",
            preview: "Mock Preview",
            timestamp: Date(),
            source: content.sourceApp.rawValue,
            isFavorite: false
        )
    }
    
    func toggleFavorite(itemId: UUID) async throws {
        // Mock implementation
    }
    
    func deleteContent(itemId: UUID) async throws {
        // Mock implementation
    }
}