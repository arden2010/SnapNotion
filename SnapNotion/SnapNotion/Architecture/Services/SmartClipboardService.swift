//
//  SmartClipboardService.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import Foundation
import UIKit
import Combine
import UniformTypeIdentifiers

// MARK: - Smart Clipboard Service

/// Intelligent clipboard monitoring with content analysis and duplicate detection
@MainActor
class SmartClipboardService: NSObject, ObservableObject {
    
    static let shared = SmartClipboardService()
    
    // MARK: - Published Properties
    @Published var hasTextContent: Bool = false
    @Published var hasImageContent: Bool = false  
    @Published var hasURLContent: Bool = false
    @Published var lastChangeCount: Int = 0
    @Published var clipboardHistory: [ClipboardItem] = []
    @Published var suggestedActions: [ClipboardSuggestion] = []
    
    // MARK: - Configuration
    private let maxHistoryItems = 50
    private let duplicateDetectionThreshold: TimeInterval = 2.0 // seconds
    private let monitoringInterval: TimeInterval = 0.5 // Check every 500ms
    
    // MARK: - Private Properties
    private var monitoringTimer: Timer?
    private var lastClipboardHash: String = ""
    private let contentProcessor = ContentProcessingPipeline.shared
    private let sourceAppDetector = SourceAppDetector()
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        startMonitoring()
        setupNotifications()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public API
    
    /// Get current clipboard content as SharedContent
    func getCurrentClipboardContent() -> SharedContent? {
        let pasteboard = UIPasteboard.general
        
        // Detect source app
        let sourceApp = sourceAppDetector.detectCurrentSourceApp()
        
        // Check for different content types in priority order
        
        // 1. URLs (highest priority for web content)
        if let url = pasteboard.url {
            return SharedContent(
                type: .url,
                data: nil,
                text: url.absoluteString,
                url: url.absoluteString,
                sourceApp: sourceApp,
                metadata: createMetadata(for: url)
            )
        }
        
        // 2. Images
        if let image = pasteboard.image {
            let imageData = image.jpegData(compressionQuality: 0.8)
            return SharedContent(
                type: .image,
                data: imageData,
                text: nil,
                url: nil,
                sourceApp: sourceApp,
                metadata: createMetadata(for: image)
            )
        }
        
        // 3. Rich text / HTML
        if pasteboard.hasStrings, let string = pasteboard.string {
            let contentType: ContentType
            
            // Detect if it's a URL in text format
            if isValidURL(string) {
                contentType = .url
            } else if containsHTMLTags(string) {
                contentType = .mixed
            } else {
                contentType = .text
            }
            
            return SharedContent(
                type: contentType,
                data: string.data(using: .utf8),
                text: string,
                url: isValidURL(string) ? string : nil,
                sourceApp: sourceApp,
                metadata: createMetadata(for: string)
            )
        }
        
        // 4. Files/Documents
        if let itemProviders = pasteboard.itemProviders.first {
            return processItemProvider(itemProviders, sourceApp: sourceApp)
        }
        
        return nil
    }
    
    /// Start intelligent clipboard monitoring
    func startMonitoring() {
        guard monitoringTimer == nil else { return }
        
        updateClipboardStatus()
        
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { _ in
            Task { @MainActor in
                self.checkClipboardChanges()
            }
        }
        
        print("🔍 Smart clipboard monitoring started")
    }
    
    /// Stop clipboard monitoring
    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        print("⏹️ Smart clipboard monitoring stopped")
    }
    
    /// Process clipboard content immediately
    func captureCurrentClipboard() async throws -> ContentNode? {
        guard let content = getCurrentClipboardContent() else {
            throw SnapNotionError.clipboardAccessFailed
        }
        
        // Add to history
        addToHistory(content)
        
        // Process through pipeline
        do {
            let contentNode = try await contentProcessor.processContent(content)
            print("✅ Clipboard content processed: \(contentNode.title)")
            return contentNode
        } catch {
            reportError(
                SnapNotionError.contentProcessingFailed(underlying: error.localizedDescription),
                in: "SmartClipboardService",
                operation: "captureCurrentClipboard"
            )
            throw error
        }
    }
    
    // MARK: - Monitoring Implementation
    
    private func checkClipboardChanges() {
        let pasteboard = UIPasteboard.general
        let currentChangeCount = pasteboard.changeCount
        
        // Check if clipboard changed
        guard currentChangeCount != lastChangeCount else { return }
        
        // Calculate content hash to detect duplicates
        let currentHash = calculateClipboardHash()
        guard currentHash != lastClipboardHash else {
            // Same content, just update change count
            lastChangeCount = currentChangeCount
            return
        }
        
        // New unique content detected
        lastChangeCount = currentChangeCount
        lastClipboardHash = currentHash
        
        // Update status
        updateClipboardStatus()
        
        // Generate suggestions
        generateSuggestions()
        
        // Auto-capture if enabled (could be a user setting)
        if shouldAutoCapture() {
            Task {
                try? await captureCurrentClipboard()
            }
        }
        
        print("📋 Clipboard changed: \(hasTextContent ? "text" : ""), \(hasImageContent ? "image" : ""), \(hasURLContent ? "url" : "")")
    }
    
    private func updateClipboardStatus() {
        let pasteboard = UIPasteboard.general
        
        hasTextContent = pasteboard.hasStrings && pasteboard.string?.isEmpty == false
        hasImageContent = pasteboard.hasImages
        hasURLContent = pasteboard.hasURLs || (pasteboard.string != nil && isValidURL(pasteboard.string!))
        
        // Clean up old suggestions
        if !hasTextContent && !hasImageContent && !hasURLContent {
            suggestedActions.removeAll()
        }
    }
    
    private func calculateClipboardHash() -> String {
        let pasteboard = UIPasteboard.general
        var hashComponents: [String] = []
        
        if let string = pasteboard.string {
            hashComponents.append("text:\(string.prefix(100))")
        }
        
        if pasteboard.hasImages {
            hashComponents.append("image:present")
        }
        
        if let url = pasteboard.url {
            hashComponents.append("url:\(url.absoluteString)")
        }
        
        return hashComponents.joined(separator: "|").sha256
    }
    
    private func generateSuggestions() {
        guard let content = getCurrentClipboardContent() else {
            suggestedActions.removeAll()
            return
        }
        
        var suggestions: [ClipboardSuggestion] = []
        
        // Always suggest basic capture
        suggestions.append(ClipboardSuggestion(
            id: UUID(),
            title: "Capture to SnapNotion",
            description: "Save this content to your library",
            action: .capture,
            priority: .medium,
            icon: "plus.circle.fill"
        ))
        
        // Content-specific suggestions
        switch content.type {
        case .url:
            suggestions.append(ClipboardSuggestion(
                id: UUID(),
                title: "Archive Web Page",
                description: "Save full page content with screenshots",
                action: .archiveWebPage,
                priority: .high,
                icon: "globe"
            ))
            
        case .text:
            if content.text?.count ?? 0 > 200 {
                suggestions.append(ClipboardSuggestion(
                    id: UUID(),
                    title: "Generate Summary",
                    description: "Create AI summary and extract key points",
                    action: .generateSummary,
                    priority: .medium,
                    icon: "doc.text.magnifyingglass"
                ))
            }
            
            if containsActionableText(content.text) {
                suggestions.append(ClipboardSuggestion(
                    id: UUID(),
                    title: "Extract Tasks",
                    description: "Find and create tasks from this content",
                    action: .extractTasks,
                    priority: .high,
                    icon: "checklist"
                ))
            }
            
        case .image:
            suggestions.append(ClipboardSuggestion(
                id: UUID(),
                title: "Extract Text (OCR)",
                description: "Convert image text to searchable content",
                action: .performOCR,
                priority: .high,
                icon: "doc.viewfinder"
            ))
            
        default:
            break
        }
        
        // Time-sensitive suggestions
        if isRecentlyCopied(content) && content.sourceApp != .other {
            suggestions.insert(ClipboardSuggestion(
                id: UUID(),
                title: "Quick Capture",
                description: "Recently copied from \(content.sourceApp.displayName)",
                action: .quickCapture,
                priority: .urgent,
                icon: "bolt.circle.fill"
            ), at: 0)
        }
        
        suggestedActions = suggestions
    }
    
    // MARK: - Content Analysis Helpers
    
    private func processItemProvider(_ provider: NSItemProvider, sourceApp: AppSource) -> SharedContent? {
        // Handle different UTTypes
        if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
            // PDF document
            return SharedContent(
                type: .document,
                data: nil, // Would need to load asynchronously
                text: nil,
                url: nil,
                sourceApp: sourceApp,
                metadata: ["fileType": "pdf"]
            )
        }
        
        // Add more file type handling as needed
        return nil
    }
    
    private func isValidURL(_ string: String) -> Bool {
        guard let url = URL(string: string) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }
    
    private func containsHTMLTags(_ string: String) -> Bool {
        return string.contains("<") && string.contains(">")
    }
    
    private func containsActionableText(_ text: String?) -> Bool {
        guard let text = text else { return false }
        
        let actionKeywords = ["todo", "task", "action", "deadline", "due", "reminder", "schedule", "meeting", "call"]
        let lowercasedText = text.lowercased()
        
        return actionKeywords.contains { lowercasedText.contains($0) }
    }
    
    private func isRecentlyCopied(_ content: SharedContent) -> Bool {
        // Check if this content was copied within the last few seconds
        return true // Simplified for now - could track timing
    }
    
    private func shouldAutoCapture() -> Bool {
        // Could be a user preference
        return false // Disabled by default to avoid overwhelming user
    }
    
    private func createMetadata(for url: URL) -> [String: Any] {
        return [
            "clipboardType": "url",
            "domain": url.host ?? "unknown",
            "scheme": url.scheme ?? "unknown",
            "captureTime": Date().timeIntervalSince1970
        ]
    }
    
    private func createMetadata(for image: UIImage) -> [String: Any] {
        return [
            "clipboardType": "image",
            "imageSize": "\(image.size.width)x\(image.size.height)",
            "captureTime": Date().timeIntervalSince1970
        ]
    }
    
    private func createMetadata(for text: String) -> [String: Any] {
        return [
            "clipboardType": "text",
            "textLength": text.count,
            "wordCount": text.components(separatedBy: .whitespacesAndNewlines).count,
            "captureTime": Date().timeIntervalSince1970
        ]
    }
    
    private func addToHistory(_ content: SharedContent) {
        let item = ClipboardItem(
            id: UUID(),
            content: content,
            timestamp: Date()
        )
        
        clipboardHistory.insert(item, at: 0)
        
        // Maintain history size limit
        if clipboardHistory.count > maxHistoryItems {
            clipboardHistory.removeLast()
        }
    }
    
    private func setupNotifications() {
        // Listen for app becoming active to check clipboard
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { _ in
                Task { @MainActor in
                    self.checkClipboardChanges()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Source App Detection

class SourceAppDetector {
    func detectCurrentSourceApp() -> AppSource {
        // This is a simplified implementation
        // In a real app, you might use more sophisticated detection
        // based on pasteboard metadata or system APIs
        
        let pasteboard = UIPasteboard.general
        
        // Check for specific app indicators in pasteboard metadata
        if let source = pasteboard.string, source.contains("safari-") {
            return .safari
        }
        
        // Default to clipboard
        return .clipboard
    }
}

// MARK: - Supporting Types

struct ClipboardItem: Identifiable {
    let id: UUID
    let content: SharedContent
    let timestamp: Date
}

struct ClipboardSuggestion: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let action: ClipboardAction
    let priority: SuggestionPriority
    let icon: String
}

enum ClipboardAction {
    case capture
    case quickCapture
    case archiveWebPage
    case generateSummary
    case extractTasks
    case performOCR
    case shareToApp(String)
}

enum SuggestionPriority: Int, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2
    case urgent = 3
}

// MARK: - String Hashing Extension

extension String {
    var sha256: String {
        guard let data = self.data(using: .utf8) else { return "" }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// Add CommonCrypto import for hashing
import CommonCrypto