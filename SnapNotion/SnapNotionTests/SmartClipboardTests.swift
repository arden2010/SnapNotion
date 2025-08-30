//
//  SmartClipboardTests.swift
//  SnapNotionTests
//
//  Created by A. C. on 8/30/25.
//

import XCTest
@testable import SnapNotion

@MainActor
final class SmartClipboardTests: XCTestCase {
    
    var clipboardService: SmartClipboardService!
    
    override func setUpWithError() throws {
        super.setUp()
        clipboardService = SmartClipboardService.shared
    }
    
    override func tearDownWithError() throws {
        clipboardService.stopMonitoring()
        clipboardService = nil
        super.tearDown()
    }
    
    // MARK: - Clipboard Content Detection Tests
    
    func testTextClipboardDetection() {
        // Given
        let testText = "This is test clipboard content"
        UIPasteboard.general.string = testText
        
        // When
        let content = clipboardService.getCurrentClipboardContent()
        
        // Then
        XCTAssertNotNil(content)
        XCTAssertEqual(content?.type, .text)
        XCTAssertEqual(content?.text, testText)
        XCTAssertEqual(content?.sourceApp, .clipboard)
    }
    
    func testURLClipboardDetection() {
        // Given
        let testURL = "https://www.example.com/test"
        UIPasteboard.general.string = testURL
        
        // When
        let content = clipboardService.getCurrentClipboardContent()
        
        // Then
        XCTAssertNotNil(content)
        XCTAssertEqual(content?.type, .url)
        XCTAssertEqual(content?.text, testURL)
        XCTAssertEqual(content?.url, testURL)
    }
    
    func testImageClipboardDetection() {
        // Given
        let testImage = UIImage(systemName: "photo")!
        UIPasteboard.general.image = testImage
        
        // When
        let content = clipboardService.getCurrentClipboardContent()
        
        // Then
        XCTAssertNotNil(content)
        XCTAssertEqual(content?.type, .image)
        XCTAssertNotNil(content?.data)
    }
    
    // MARK: - Content Hash Tests
    
    func testContentHashGeneration() {
        // Given
        let testText1 = "Same content"
        let testText2 = "Same content"
        let testText3 = "Different content"
        
        // When
        UIPasteboard.general.string = testText1
        let hash1 = clipboardService.calculateClipboardHash()
        
        UIPasteboard.general.string = testText2
        let hash2 = clipboardService.calculateClipboardHash()
        
        UIPasteboard.general.string = testText3
        let hash3 = clipboardService.calculateClipboardHash()
        
        // Then
        XCTAssertEqual(hash1, hash2, "Same content should produce same hash")
        XCTAssertNotEqual(hash1, hash3, "Different content should produce different hash")
    }
    
    // MARK: - Suggestion Generation Tests
    
    func testTextSuggestionGeneration() {
        // Given
        let longText = String(repeating: "This is a long text that should generate summary suggestions. ", count: 10)
        UIPasteboard.general.string = longText
        
        // When
        clipboardService.generateSuggestions()
        
        // Then
        XCTAssertFalse(clipboardService.suggestedActions.isEmpty)
        
        let summaryAction = clipboardService.suggestedActions.first { $0.action == .generateSummary }
        XCTAssertNotNil(summaryAction)
    }
    
    func testURLSuggestionGeneration() {
        // Given
        let testURL = "https://www.example.com/article"
        UIPasteboard.general.string = testURL
        
        // When
        clipboardService.generateSuggestions()
        
        // Then
        XCTAssertFalse(clipboardService.suggestedActions.isEmpty)
        
        let archiveAction = clipboardService.suggestedActions.first { $0.action == .archiveWebPage }
        XCTAssertNotNil(archiveAction)
    }
    
    func testTaskExtractionSuggestion() {
        // Given
        let taskText = "Remember to call John tomorrow and schedule the meeting for next week. Don't forget the deadline is Friday."
        UIPasteboard.general.string = taskText
        
        // When
        clipboardService.generateSuggestions()
        
        // Then
        let extractTasksAction = clipboardService.suggestedActions.first { $0.action == .extractTasks }
        XCTAssertNotNil(extractTasksAction, "Should suggest task extraction for actionable text")
    }
    
    // MARK: - Performance Tests
    
    func testClipboardMonitoringPerformance() {
        measure {
            // Simulate multiple clipboard changes
            for i in 0..<100 {
                UIPasteboard.general.string = "Test content \(i)"
                _ = clipboardService.getCurrentClipboardContent()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func clearClipboard() {
        UIPasteboard.general.string = ""
    }
}

// MARK: - String Extension Tests

extension SmartClipboardTests {
    
    func testStringHashingExtension() {
        // Given
        let text1 = "Hello World"
        let text2 = "Hello World"
        let text3 = "Different Text"
        
        // When/Then
        XCTAssertEqual(text1.sha256, text2.sha256)
        XCTAssertNotEqual(text1.sha256, text3.sha256)
        XCTAssertFalse(text1.sha256.isEmpty)
    }
    
    func testURLValidation() {
        // Test cases for URL validation
        let validURLs = [
            "https://www.example.com",
            "http://example.com/path",
            "https://sub.domain.com/path?query=value"
        ]
        
        let invalidURLs = [
            "not a url",
            "ftp://example.com",
            "mailto:test@example.com",
            ""
        ]
        
        for url in validURLs {
            UIPasteboard.general.string = url
            let content = clipboardService.getCurrentClipboardContent()
            XCTAssertEqual(content?.type, .url, "Should detect \(url) as URL")
        }
        
        for url in invalidURLs {
            UIPasteboard.general.string = url
            let content = clipboardService.getCurrentClipboardContent()
            XCTAssertNotEqual(content?.type, .url, "Should not detect \(url) as URL")
        }
    }
}