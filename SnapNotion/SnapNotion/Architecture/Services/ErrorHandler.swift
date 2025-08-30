//
//  ErrorHandler.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import Foundation
import SwiftUI
import os.log

// MARK: - App Error Protocol
protocol AppError: LocalizedError {
    var errorCode: String { get }
    var severity: ErrorSeverity { get }
    var userMessage: String { get }
    var debugInfo: [String: Any] { get }
}

// MARK: - Error Severity
enum ErrorSeverity {
    case low        // Minor issues, app continues normally
    case medium     // Some functionality affected, but app usable
    case high       // Major functionality broken, but app doesn't crash
    case critical   // App-breaking errors
}

// MARK: - SnapNotion Errors
enum SnapNotionError: AppError {
    // Content Processing Errors
    case contentProcessingFailed(reason: String, underlyingError: Error?)
    case ocrExtractionFailed(Error?)
    case aiProcessingTimeout
    case unsupportedContentType(String)
    
    // Storage Errors
    case coreDataError(Error)
    case fileSystemError(Error)
    case cloudKitSyncError(Error)
    case storageQuotaExceeded
    
    // Network Errors
    case networkConnectionFailed
    case apiRateLimitExceeded
    case serverError(statusCode: Int, message: String?)
    case authenticationFailed
    
    // Share Extension Errors
    case shareExtensionError(ShareExtensionError)
    case appGroupAccessDenied
    
    // Security Errors
    case encryptionFailed(SecurityError)
    case keychainError(SecurityError)
    
    // UI/UX Errors
    case cameraAccessDenied
    case photoLibraryAccessDenied
    case microphoneAccessDenied
    case locationAccessDenied
    
    var errorCode: String {
        switch self {
        case .contentProcessingFailed: return "CONTENT_001"
        case .ocrExtractionFailed: return "CONTENT_002"
        case .aiProcessingTimeout: return "CONTENT_003"
        case .unsupportedContentType: return "CONTENT_004"
        case .coreDataError: return "STORAGE_001"
        case .fileSystemError: return "STORAGE_002"
        case .cloudKitSyncError: return "STORAGE_003"
        case .storageQuotaExceeded: return "STORAGE_004"
        case .networkConnectionFailed: return "NETWORK_001"
        case .apiRateLimitExceeded: return "NETWORK_002"
        case .serverError: return "NETWORK_003"
        case .authenticationFailed: return "NETWORK_004"
        case .shareExtensionError: return "SHARE_001"
        case .appGroupAccessDenied: return "SHARE_002"
        case .encryptionFailed: return "SECURITY_001"
        case .keychainError: return "SECURITY_002"
        case .cameraAccessDenied: return "PERMISSIONS_001"
        case .photoLibraryAccessDenied: return "PERMISSIONS_002"
        case .microphoneAccessDenied: return "PERMISSIONS_003"
        case .locationAccessDenied: return "PERMISSIONS_004"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .aiProcessingTimeout, .locationAccessDenied:
            return .low
        case .ocrExtractionFailed, .microphoneAccessDenied, .apiRateLimitExceeded:
            return .medium
        case .contentProcessingFailed, .networkConnectionFailed, .cameraAccessDenied, .photoLibraryAccessDenied:
            return .high
        case .coreDataError, .encryptionFailed, .appGroupAccessDenied:
            return .critical
        default:
            return .medium
        }
    }
    
    var userMessage: String {
        switch self {
        case .contentProcessingFailed:
            return "Unable to process content. Please try again."
        case .ocrExtractionFailed:
            return "Could not extract text from image. The image may be too blurry or unclear."
        case .aiProcessingTimeout:
            return "AI processing is taking longer than expected. Content will be saved without analysis."
        case .unsupportedContentType(let type):
            return "Content type '\(type)' is not supported yet."
        case .coreDataError:
            return "There was a problem saving your data. Please restart the app."
        case .fileSystemError:
            return "Unable to save files. Please check available storage."
        case .cloudKitSyncError:
            return "Sync temporarily unavailable. Your data is saved locally."
        case .storageQuotaExceeded:
            return "Storage space full. Please delete some content or upgrade."
        case .networkConnectionFailed:
            return "No internet connection. Some features may be limited."
        case .apiRateLimitExceeded:
            return "Too many requests. Please wait a moment and try again."
        case .serverError(_, let message):
            return message ?? "Server error occurred. Please try again later."
        case .authenticationFailed:
            return "Authentication failed. Please sign in again."
        case .shareExtensionError:
            return "Unable to import shared content. Please try again."
        case .appGroupAccessDenied:
            return "App configuration error. Please reinstall the app."
        case .encryptionFailed, .keychainError:
            return "Security error occurred. Your data remains safe."
        case .cameraAccessDenied:
            return "Camera access required. Please enable in Settings > Privacy > Camera."
        case .photoLibraryAccessDenied:
            return "Photo library access required. Please enable in Settings > Privacy > Photos."
        case .microphoneAccessDenied:
            return "Microphone access required for voice notes. Please enable in Settings > Privacy > Microphone."
        case .locationAccessDenied:
            return "Location access helps organize content by place. You can enable it in Settings > Privacy > Location."
        }
    }
    
    var debugInfo: [String: Any] {
        var info: [String: Any] = [
            "errorCode": errorCode,
            "severity": String(describing: severity),
            "timestamp": Date().iso8601String
        ]
        
        switch self {
        case .contentProcessingFailed(let reason, let underlyingError):
            info["reason"] = reason
            info["underlyingError"] = underlyingError?.localizedDescription
        case .ocrExtractionFailed(let error):
            info["underlyingError"] = error?.localizedDescription
        case .unsupportedContentType(let type):
            info["contentType"] = type
        case .coreDataError(let error), .fileSystemError(let error), .cloudKitSyncError(let error):
            info["underlyingError"] = error.localizedDescription
        case .serverError(let statusCode, let message):
            info["statusCode"] = statusCode
            info["serverMessage"] = message
        case .shareExtensionError(let error):
            info["shareExtensionError"] = error.localizedDescription
        case .encryptionFailed(let error), .keychainError(let error):
            info["securityError"] = error.localizedDescription
        default:
            break
        }
        
        return info
    }
    
    var errorDescription: String? {
        return userMessage
    }
}

// MARK: - Global Error Handler
@MainActor
class ErrorHandler: ObservableObject {
    
    static let shared = ErrorHandler()
    
    @Published var currentError: AppError?
    @Published var showingError = false
    
    private let logger = Logger(subsystem: "com.snapnotion.app", category: "ErrorHandler")
    
    private init() {}
    
    // MARK: - Public Methods
    func handle(_ error: Error) {
        let appError: AppError
        
        if let snapError = error as? SnapNotionError {
            appError = snapError
        } else {
            // Convert generic errors to app-specific errors
            appError = convertGenericError(error)
        }
        
        // Log the error
        logError(appError)
        
        // Show error to user if appropriate
        if shouldShowToUser(appError) {
            currentError = appError
            showingError = true
        }
        
        // Send to analytics (in production)
        sendToAnalytics(appError)
    }
    
    func clearError() {
        currentError = nil
        showingError = false
    }
    
    // MARK: - Private Methods
    private func convertGenericError(_ error: Error) -> AppError {
        // Convert common system errors to our error types
        if error.localizedDescription.contains("network") {
            return SnapNotionError.networkConnectionFailed
        } else if error.localizedDescription.contains("CoreData") {
            return SnapNotionError.coreDataError(error)
        } else {
            return SnapNotionError.contentProcessingFailed(reason: "Unknown error", underlyingError: error)
        }
    }
    
    private func shouldShowToUser(_ error: AppError) -> Bool {
        // Only show medium and high severity errors to users
        // Critical errors might be handled differently (restart app, etc.)
        // Low errors are logged but not shown
        return error.severity == .medium || error.severity == .high
    }
    
    private func logError(_ error: AppError) {
        let debugInfo = error.debugInfo
        
        switch error.severity {
        case .low:
            logger.info("Low severity error: \(error.errorCode) - \(error.userMessage)")
        case .medium:
            logger.notice("Medium severity error: \(error.errorCode) - \(error.userMessage) - Debug: \(debugInfo)")
        case .high:
            logger.error("High severity error: \(error.errorCode) - \(error.userMessage) - Debug: \(debugInfo)")
        case .critical:
            logger.critical("Critical error: \(error.errorCode) - \(error.userMessage) - Debug: \(debugInfo)")
        }
    }
    
    private func sendToAnalytics(_ error: AppError) {
        // In production, send error data to analytics service
        // For privacy, only send error codes and severity, not user data
        let analyticsData: [String: Any] = [
            "errorCode": error.errorCode,
            "severity": String(describing: error.severity),
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // TODO: Implement analytics service integration
        logger.info("Would send to analytics: \(analyticsData)")
    }
}

// MARK: - Error View Modifier
struct ErrorHandling: ViewModifier {
    @StateObject private var errorHandler = ErrorHandler.shared
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $errorHandler.showingError) {
                Button("OK") {
                    errorHandler.clearError()
                }
                
                // Add retry button for certain types of errors
                if let error = errorHandler.currentError,
                   canRetry(error) {
                    Button("Retry") {
                        // Handle retry logic
                        errorHandler.clearError()
                    }
                }
            } message: {
                Text(errorHandler.currentError?.userMessage ?? "An unknown error occurred")
            }
    }
    
    private func canRetry(_ error: AppError) -> Bool {
        // Define which errors can be retried
        switch error.errorCode {
        case "CONTENT_001", "CONTENT_002", "NETWORK_001", "NETWORK_002":
            return true
        default:
            return false
        }
    }
}

// MARK: - View Extension
extension View {
    func handleErrors() -> some View {
        modifier(ErrorHandling())
    }
}

// MARK: - Date Extension
private extension Date {
    var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }
}