//
//  ErrorHandlingTests.swift
//  SnapNotionTests
//
//  Created by A. C. on 8/30/25.
//

import XCTest
@testable import SnapNotion

final class ErrorHandlingTests: XCTestCase {
    
    var errorManager: ErrorRecoveryManager!
    
    override func setUpWithError() throws {
        super.setUp()
        errorManager = ErrorRecoveryManager.shared
        errorManager.clearErrorHistory() // Reset for testing
    }
    
    override func tearDownWithError() throws {
        errorManager = nil
        super.tearDown()
    }
    
    // MARK: - Error Classification Tests
    
    func testNetworkErrorClassification() {
        // Given
        let networkError = SnapNotionError.networkConnectionFailed
        
        // When
        let severity = errorManager.classifyError(networkError)
        
        // Then
        XCTAssertEqual(severity, .recoverable)
    }
    
    func testCriticalErrorClassification() {
        // Given
        let criticalError = SnapNotionError.coreDataFetchFailed(entity: "ContentNode")
        
        // When
        let severity = errorManager.classifyError(criticalError)
        
        // Then
        XCTAssertEqual(severity, .critical)
    }
    
    func testWarningErrorClassification() {
        // Given
        let warningError = SnapNotionError.ocrExtractionFailed(reason: "Low quality image")
        
        // When
        let severity = errorManager.classifyError(warningError)
        
        // Then
        XCTAssertEqual(severity, .warning)
    }
    
    // MARK: - Error Recovery Tests
    
    func testNetworkErrorRecovery() {
        // Given
        let networkError = SnapNotionError.networkConnectionFailed
        
        // When
        let canRecover = errorManager.canRecover(from: networkError)
        let recoveryOptions = errorManager.getRecoveryOptions(for: networkError)
        
        // Then
        XCTAssertTrue(canRecover)
        XCTAssertFalse(recoveryOptions.isEmpty)
        XCTAssertTrue(recoveryOptions.contains("retry"))
    }
    
    func testOCRErrorRecovery() {
        // Given
        let ocrError = SnapNotionError.ocrExtractionFailed(reason: "Image too blurry")
        
        // When
        let canRecover = errorManager.canRecover(from: ocrError)
        let recoveryOptions = errorManager.getRecoveryOptions(for: ocrError)
        
        // Then
        XCTAssertTrue(canRecover)
        XCTAssertTrue(recoveryOptions.contains("manual_entry"))
        XCTAssertTrue(recoveryOptions.contains("retry_with_enhancement"))
    }
    
    func testCriticalErrorNoRecovery() {
        // Given
        let criticalError = SnapNotionError.coreDataFetchFailed(entity: "ContentNode")
        
        // When
        let canRecover = errorManager.canRecover(from: criticalError)
        
        // Then
        XCTAssertFalse(canRecover)
    }
    
    // MARK: - Error History Tests
    
    func testErrorHistoryTracking() {
        // Given
        let error1 = SnapNotionError.networkConnectionFailed
        let error2 = SnapNotionError.ocrExtractionFailed(reason: "Test")
        
        // When
        errorManager.recordError(error1, in: "NetworkService", operation: "fetch")
        errorManager.recordError(error2, in: "OCRProcessor", operation: "extract")
        
        // Then
        let history = errorManager.getErrorHistory()
        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history.first?.error, error1)
        XCTAssertEqual(history.last?.error, error2)
    }
    
    func testErrorFrequencyTracking() {
        // Given
        let repeatedError = SnapNotionError.networkConnectionFailed
        
        // When
        for _ in 0..<5 {
            errorManager.recordError(repeatedError, in: "NetworkService", operation: "fetch")
        }
        
        // Then
        let frequency = errorManager.getErrorFrequency(repeatedError)
        XCTAssertEqual(frequency, 5)
    }
    
    // MARK: - Error Reporting Tests
    
    func testErrorReporting() {
        // Given
        let testError = SnapNotionError.contentProcessingFailed(underlying: "Test failure")
        let expectation = self.expectation(description: "Error reported")
        
        // When
        reportError(testError, in: "TestComponent", operation: "testOperation")
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let history = self.errorManager.getErrorHistory()
            XCTAssertFalse(history.isEmpty)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - Error Context Tests
    
    func testErrorContextPreservation() {
        // Given
        let error = SnapNotionError.aiProcessingUnavailable
        let context: [String: Any] = [
            "userId": "test-user",
            "operation": "content-analysis",
            "timestamp": Date()
        ]
        
        // When
        errorManager.recordError(error, in: "AIService", operation: "analyze", context: context)
        
        // Then
        let history = errorManager.getErrorHistory()
        XCTAssertEqual(history.first?.context["userId"] as? String, "test-user")
        XCTAssertEqual(history.first?.context["operation"] as? String, "content-analysis")
    }
    
    // MARK: - Performance Tests
    
    func testErrorHandlingPerformance() {
        measure {
            for i in 0..<1000 {
                let error = SnapNotionError.contentProcessingFailed(underlying: "Error \(i)")
                errorManager.recordError(error, in: "TestComponent", operation: "performance_test")
            }
        }
    }
    
    // MARK: - Error Equality Tests
    
    func testErrorEquality() {
        // Given
        let error1 = SnapNotionError.networkConnectionFailed
        let error2 = SnapNotionError.networkConnectionFailed
        let error3 = SnapNotionError.aiProcessingUnavailable
        
        // Then
        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }
    
    func testErrorWithParametersEquality() {
        // Given
        let error1 = SnapNotionError.contentProcessingFailed(underlying: "Same message")
        let error2 = SnapNotionError.contentProcessingFailed(underlying: "Same message")
        let error3 = SnapNotionError.contentProcessingFailed(underlying: "Different message")
        
        // Then
        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }
    
    // MARK: - Error Description Tests
    
    func testErrorDescriptions() {
        let errors: [SnapNotionError] = [
            .networkConnectionFailed,
            .contentProcessingFailed(underlying: "Test"),
            .ocrExtractionFailed(reason: "Image quality"),
            .aiProcessingUnavailable,
            .clipboardAccessFailed,
            .coreDataFetchFailed(entity: "ContentNode")
        ]
        
        for error in errors {
            XCTAssertFalse(error.localizedDescription.isEmpty, "Error should have description: \(error)")
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true, "Error should have error description: \(error)")
        }
    }
}