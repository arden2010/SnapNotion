//
//  ErrorHandling.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import Foundation
import Combine
import SwiftUI

// MARK: - SnapNotion Error Types

/// Comprehensive error types for all SnapNotion operations
enum SnapNotionError: Error, Equatable, LocalizedError {
    // Content Processing Errors
    case contentProcessingFailed(underlying: String)
    case ocrExtractionFailed(reason: String)
    case aiProcessingUnavailable
    case aiProcessingTimeout
    case invalidContentFormat(expected: String, received: String)
    
    // Data Persistence Errors
    case coreDataSaveFailed(reason: String)
    case coreDataFetchFailed(entity: String)
    case dataMigrationFailed(fromVersion: String, toVersion: String)
    case dataCorruption(entity: String, objectID: String)
    
    // Synchronization Errors
    case cloudKitSyncFailed(reason: String)
    case syncConflict(localVersion: String, remoteVersion: String)
    case networkUnavailable
    case quotaExceeded(current: Int64, limit: Int64)
    
    // Content Capture Errors
    case cameraAccessDenied
    case photoLibraryAccessDenied
    case clipboardAccessFailed
    case documentScanningFailed(reason: String)
    
    // Search Errors
    case searchIndexCorrupted
    case searchQueryTooComplex
    case searchTimeout
    
    // User Experience Errors
    case insufficientStorageSpace(required: Int64, available: Int64)
    case unsupportedFileType(fileType: String)
    case fileTooLarge(size: Int64, maxSize: Int64)
    
    // System Errors
    case memoryPressure
    case backgroundProcessingLimitExceeded
    case featureNotAvailable(feature: String, reason: String)
    
    var errorDescription: String? {
        switch self {
        case .contentProcessingFailed(let underlying):
            return "Content processing failed: \(underlying)"
        case .ocrExtractionFailed(let reason):
            return "Text extraction failed: \(reason)"
        case .aiProcessingUnavailable:
            return "AI processing is temporarily unavailable"
        case .aiProcessingTimeout:
            return "AI processing timed out"
        case .invalidContentFormat(let expected, let received):
            return "Expected \(expected) format, but received \(received)"
        case .coreDataSaveFailed(let reason):
            return "Failed to save data: \(reason)"
        case .coreDataFetchFailed(let entity):
            return "Failed to fetch \(entity) data"
        case .dataMigrationFailed(let from, let to):
            return "Data migration failed from \(from) to \(to)"
        case .dataCorruption(let entity, let objectID):
            return "Data corruption detected in \(entity): \(objectID)"
        case .cloudKitSyncFailed(let reason):
            return "Cloud sync failed: \(reason)"
        case .syncConflict(let local, let remote):
            return "Sync conflict between local (\(local)) and remote (\(remote)) versions"
        case .networkUnavailable:
            return "Network connection unavailable"
        case .quotaExceeded(let current, let limit):
            return "Storage quota exceeded: \(current) bytes of \(limit) bytes used"
        case .cameraAccessDenied:
            return "Camera access denied. Please enable in Settings > Privacy > Camera"
        case .photoLibraryAccessDenied:
            return "Photo library access denied. Please enable in Settings > Privacy > Photos"
        case .clipboardAccessFailed:
            return "Unable to access clipboard content"
        case .documentScanningFailed(let reason):
            return "Document scanning failed: \(reason)"
        case .searchIndexCorrupted:
            return "Search index corrupted. Rebuilding automatically..."
        case .searchQueryTooComplex:
            return "Search query too complex. Please simplify your search terms"
        case .searchTimeout:
            return "Search timed out. Please try a more specific query"
        case .insufficientStorageSpace(let required, let available):
            return "Insufficient storage space: need \(ByteCountFormatter.string(fromByteCount: required, countStyle: .file)), have \(ByteCountFormatter.string(fromByteCount: available, countStyle: .file))"
        case .unsupportedFileType(let fileType):
            return "File type '\(fileType)' is not supported"
        case .fileTooLarge(let size, let maxSize):
            return "File too large: \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)) (max: \(ByteCountFormatter.string(fromByteCount: maxSize, countStyle: .file)))"
        case .memoryPressure:
            return "Device is running low on memory. Please close other apps"
        case .backgroundProcessingLimitExceeded:
            return "Background processing time exceeded. Processing will continue when app is active"
        case .featureNotAvailable(let feature, let reason):
            return "\(feature) is not available: \(reason)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .aiProcessingUnavailable, .aiProcessingTimeout:
            return "Content will be processed when AI services are restored"
        case .networkUnavailable:
            return "Check your internet connection and try again"
        case .cameraAccessDenied:
            return "Go to Settings > Privacy & Security > Camera and enable access for SnapNotion"
        case .photoLibraryAccessDenied:
            return "Go to Settings > Privacy & Security > Photos and enable access for SnapNotion"
        case .insufficientStorageSpace:
            return "Free up space by deleting unused content or upgrading your storage plan"
        case .searchIndexCorrupted:
            return "The search index will be rebuilt automatically in the background"
        case .memoryPressure:
            return "Close other apps to free up memory, then try again"
        case .syncConflict:
            return "You can resolve this conflict by choosing which version to keep"
        default:
            return "Try again in a few moments. If the problem persists, contact support"
        }
    }
    
    /// Severity level for error reporting and user notification
    var severity: ErrorSeverity {
        switch self {
        case .dataCorruption, .dataMigrationFailed:
            return .critical
        case .coreDataSaveFailed, .coreDataFetchFailed, .searchIndexCorrupted:
            return .high
        case .aiProcessingUnavailable, .networkUnavailable, .syncConflict:
            return .medium
        case .aiProcessingTimeout, .searchTimeout, .clipboardAccessFailed:
            return .low
        default:
            return .medium
        }
    }
    
    /// Whether this error should be automatically retried
    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .aiProcessingTimeout, .searchTimeout, .aiProcessingUnavailable:
            return true
        case .cameraAccessDenied, .photoLibraryAccessDenied, .dataCorruption, .dataMigrationFailed:
            return false
        default:
            return true
        }
    }
}

// MARK: - Error Severity

enum ErrorSeverity: String, CaseIterable {
    case low = "low"
    case medium = "medium" 
    case high = "high"
    case critical = "critical"
    
    var userNotificationRequired: Bool {
        switch self {
        case .low: return false
        case .medium, .high, .critical: return true
        }
    }
    
    var shouldLogToCrashlytics: Bool {
        switch self {
        case .low, .medium: return false
        case .high, .critical: return true
        }
    }
}

// MARK: - Error Recovery Actions

enum ErrorRecoveryAction {
    case retry(delay: TimeInterval = 0)
    case retryWithFallback(fallbackAction: () -> Void)
    case presentUserChoice(options: [RecoveryOption])
    case handleSilently
    case requireUserIntervention(message: String)
    case restartComponent(component: String)
    case fallbackToOfflineMode
    
    struct RecoveryOption {
        let title: String
        let action: () -> Void
        let isDestructive: Bool
        
        init(title: String, isDestructive: Bool = false, action: @escaping () -> Void) {
            self.title = title
            self.isDestructive = isDestructive
            self.action = action
        }
    }
}

// MARK: - Error Recovery Manager

/// Centralized error recovery and retry logic
@MainActor
class ErrorRecoveryManager: ObservableObject {
    static let shared = ErrorRecoveryManager()
    
    @Published private(set) var activeRecoveryOperations: [UUID: RecoveryOperation] = [:]
    @Published private(set) var errorHistory: [ErrorEvent] = []
    
    private let maxRetryCount = 3
    private let maxErrorHistorySize = 100
    private var retryDelayCalculator = ExponentialBackoffCalculator()
    
    private init() {}
    
    /// Main error handling entry point
    func handle(_ error: SnapNotionError, 
               context: ErrorContext,
               completion: ((ErrorRecoveryAction) -> Void)? = nil) {
        
        // Log error event
        let errorEvent = ErrorEvent(
            error: error,
            context: context,
            timestamp: Date(),
            severity: error.severity
        )
        logError(errorEvent)
        
        // Determine recovery action
        let recoveryAction = determineRecoveryAction(for: error, context: context)
        
        // Execute recovery
        executeRecovery(action: recoveryAction, for: error, context: context)
        
        completion?(recoveryAction)
    }
    
    private func determineRecoveryAction(for error: SnapNotionError, 
                                       context: ErrorContext) -> ErrorRecoveryAction {
        
        // Check retry eligibility
        if error.isRetryable && context.retryCount < maxRetryCount {
            let delay = retryDelayCalculator.calculateDelay(for: context.retryCount)
            
            // Special fallback cases
            switch error {
            case .aiProcessingUnavailable:
                return .retryWithFallback {
                    // Fallback to local processing
                    self.enableLocalProcessingMode()
                }
            case .networkUnavailable:
                return .retryWithFallback {
                    // Switch to offline mode
                    self.enableOfflineMode()
                }
            default:
                return .retry(delay: delay)
            }
        }
        
        // Handle non-retryable or exhausted retry errors
        switch error {
        case .syncConflict(let local, let remote):
            return .presentUserChoice(options: [
                ErrorRecoveryAction.RecoveryOption(title: "Keep Local Version") {
                    self.resolveSyncConflict(preferLocal: true)
                },
                ErrorRecoveryAction.RecoveryOption(title: "Keep Remote Version") {
                    self.resolveSyncConflict(preferLocal: false)
                },
                ErrorRecoveryAction.RecoveryOption(title: "Merge Changes") {
                    self.presentMergeInterface()
                }
            ])
            
        case .cameraAccessDenied, .photoLibraryAccessDenied:
            return .requireUserIntervention(message: error.recoverySuggestion ?? "Please check app permissions")
            
        case .dataCorruption:
            return .presentUserChoice(options: [
                ErrorRecoveryAction.RecoveryOption(title: "Repair Database") {
                    self.repairDatabase()
                },
                ErrorRecoveryAction.RecoveryOption(title: "Restore from Backup") {
                    self.restoreFromBackup()
                },
                ErrorRecoveryAction.RecoveryOption(title: "Reset App Data", isDestructive: true) {
                    self.resetAppData()
                }
            ])
            
        case .memoryPressure:
            return .retryWithFallback {
                self.freeMemoryResources()
            }
            
        case .searchIndexCorrupted:
            return .restartComponent(component: "SearchService")
            
        default:
            if error.severity.userNotificationRequired {
                return .requireUserIntervention(message: error.localizedDescription)
            } else {
                return .handleSilently
            }
        }
    }
    
    private func executeRecovery(action: ErrorRecoveryAction,
                               for error: SnapNotionError,
                               context: ErrorContext) {
        let operationID = UUID()
        let operation = RecoveryOperation(id: operationID, error: error, action: action, context: context)
        activeRecoveryOperations[operationID] = operation
        
        switch action {
        case .retry(let delay):
            if delay > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.executeRetry(for: operationID)
                }
            } else {
                executeRetry(for: operationID)
            }
            
        case .retryWithFallback(let fallbackAction):
            fallbackAction()
            executeRetry(for: operationID)
            
        case .presentUserChoice(let options):
            presentUserChoiceDialog(options: options, for: operationID)
            
        case .handleSilently:
            // Log but don't show to user
            completeRecoveryOperation(operationID)
            
        case .requireUserIntervention(let message):
            presentErrorAlert(message: message, for: operationID)
            
        case .restartComponent(let component):
            restartSystemComponent(component, for: operationID)
            
        case .fallbackToOfflineMode:
            enableOfflineMode()
            completeRecoveryOperation(operationID)
        }
    }
    
    private func executeRetry(for operationID: UUID) {
        guard let operation = activeRecoveryOperations[operationID] else { return }
        
        let newContext = ErrorContext(
            operation: operation.context.operation,
            component: operation.context.component,
            retryCount: operation.context.retryCount + 1,
            additionalInfo: operation.context.additionalInfo
        )
        
        // Trigger the original operation with new context
        operation.context.retryCallback?(newContext)
        completeRecoveryOperation(operationID)
    }
    
    private func completeRecoveryOperation(_ operationID: UUID) {
        activeRecoveryOperations.removeValue(forKey: operationID)
    }
    
    private func logError(_ event: ErrorEvent) {
        errorHistory.insert(event, at: 0)
        
        // Maintain history size limit
        if errorHistory.count > maxErrorHistorySize {
            errorHistory.removeLast()
        }
        
        // Log to external services if needed
        if event.severity.shouldLogToCrashlytics {
            logToCrashlytics(event)
        }
        
        print("🚨 SnapNotion Error: \(event.error.localizedDescription)")
        print("   Context: \(event.context.operation) in \(event.context.component)")
        print("   Severity: \(event.severity.rawValue)")
    }
    
    // MARK: - Recovery Action Implementations
    
    private func enableLocalProcessingMode() {
        // Switch to local-only AI processing
        print("🔄 Switching to local processing mode")
    }
    
    private func enableOfflineMode() {
        // Disable sync and enable offline-only mode
        print("🔄 Switching to offline mode")
    }
    
    private func resolveSyncConflict(preferLocal: Bool) {
        print("🔄 Resolving sync conflict, preferLocal: \(preferLocal)")
    }
    
    private func presentMergeInterface() {
        print("🔄 Presenting merge interface")
    }
    
    private func repairDatabase() {
        print("🔄 Repairing database")
    }
    
    private func restoreFromBackup() {
        print("🔄 Restoring from backup")
    }
    
    private func resetAppData() {
        print("🔄 Resetting app data")
    }
    
    private func freeMemoryResources() {
        print("🔄 Freeing memory resources")
    }
    
    private func restartSystemComponent(_ component: String, for operationID: UUID) {
        print("🔄 Restarting component: \(component)")
        completeRecoveryOperation(operationID)
    }
    
    private func presentUserChoiceDialog(options: [ErrorRecoveryAction.RecoveryOption], for operationID: UUID) {
        print("🔄 Presenting user choice dialog with \(options.count) options")
        // In real implementation, this would show a SwiftUI alert or sheet
        completeRecoveryOperation(operationID)
    }
    
    private func presentErrorAlert(message: String, for operationID: UUID) {
        print("🔄 Presenting error alert: \(message)")
        completeRecoveryOperation(operationID)
    }
    
    private func logToCrashlytics(_ event: ErrorEvent) {
        // Integration with Crashlytics or similar service
        print("📊 Logging to Crashlytics: \(event.error)")
    }
}

// MARK: - Supporting Types

struct ErrorContext {
    let operation: String
    let component: String
    let retryCount: Int
    let additionalInfo: [String: Any]
    let retryCallback: ((ErrorContext) -> Void)?
    
    init(operation: String, 
         component: String,
         retryCount: Int = 0,
         additionalInfo: [String: Any] = [:],
         retryCallback: ((ErrorContext) -> Void)? = nil) {
        self.operation = operation
        self.component = component
        self.retryCount = retryCount
        self.additionalInfo = additionalInfo
        self.retryCallback = retryCallback
    }
}

struct ErrorEvent {
    let id = UUID()
    let error: SnapNotionError
    let context: ErrorContext
    let timestamp: Date
    let severity: ErrorSeverity
}

struct RecoveryOperation {
    let id: UUID
    let error: SnapNotionError
    let action: ErrorRecoveryAction
    let context: ErrorContext
    let startTime = Date()
}

// MARK: - Exponential Backoff

class ExponentialBackoffCalculator {
    private let baseDelay: TimeInterval = 1.0
    private let maxDelay: TimeInterval = 30.0
    private let multiplier: Double = 2.0
    
    func calculateDelay(for attemptCount: Int) -> TimeInterval {
        let delay = baseDelay * pow(multiplier, Double(attemptCount))
        return min(delay, maxDelay)
    }
}

// MARK: - Error Handling View Modifier

struct ErrorHandlingViewModifier: ViewModifier {
    @StateObject private var errorRecovery = ErrorRecoveryManager.shared
    @State private var showingErrorAlert = false
    @State private var currentError: SnapNotionError?
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $showingErrorAlert, presenting: currentError) { error in
                Button("OK") {
                    currentError = nil
                }
                
                if error.isRetryable {
                    Button("Retry") {
                        retryOperation(for: error)
                    }
                }
            } message: { error in
                VStack(alignment: .leading) {
                    Text(error.localizedDescription)
                    
                    if let suggestion = error.recoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .snapNotionErrorOccurred)) { notification in
                if let error = notification.object as? SnapNotionError {
                    handleError(error)
                }
            }
    }
    
    private func handleError(_ error: SnapNotionError) {
        currentError = error
        showingErrorAlert = true
    }
    
    private func retryOperation(for error: SnapNotionError) {
        let context = ErrorContext(
            operation: "user_retry",
            component: "ui"
        )
        errorRecovery.handle(error, context: context)
    }
}

// MARK: - View Extension

extension View {
    func withErrorHandling() -> some View {
        modifier(ErrorHandlingViewModifier())
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let snapNotionErrorOccurred = Notification.Name("SnapNotionErrorOccurred")
}

// MARK: - Global Error Reporting

func reportError(_ error: SnapNotionError, 
                in component: String = "unknown",
                operation: String = "unknown",
                additionalInfo: [String: Any] = [:]) {
    
    let context = ErrorContext(
        operation: operation,
        component: component,
        additionalInfo: additionalInfo
    )
    
    Task { @MainActor in
        ErrorRecoveryManager.shared.handle(error, context: context)
    }
    
    // Also post notification for UI handling
    NotificationCenter.default.post(
        name: .snapNotionErrorOccurred,
        object: error
    )
}