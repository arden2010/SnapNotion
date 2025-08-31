//
//  InstantFeedbackManager.swift
//  SnapNotion
//
//  Manager for instant feedback system coordinating all feedback types
//  Created by A. C. on 8/31/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Instant Feedback Manager
@MainActor
class InstantFeedbackManager: ObservableObject {
    
    static let shared = InstantFeedbackManager()
    
    // MARK: - Published Properties
    @Published var isShowingProcessingBanner = false
    @Published var processingProgress: Double = 0.0
    @Published var processingMessage = ""
    
    @Published var isShowingQuickPreview = false
    @Published var previewData: PreviewData?
    
    @Published var isShowingSuccessToast = false
    @Published var successMessage = ""
    @Published var successDetails: String?
    
    @Published var isShowingMagicMoment = false
    @Published var magicMomentData: MagicMomentData?
    
    // MARK: - Computed Properties
    var isShowingInteractiveOverlay: Bool {
        return isShowingQuickPreview || isShowingMagicMoment
    }
    
    // MARK: - Private Properties
    private var processingTimer: Timer?
    private var autoHideTimer: Timer?
    private var currentProcessingId: UUID?
    
    private init() {}
    
    // MARK: - Processing Banner Methods
    func showProcessingBanner(message: String, id: UUID = UUID()) {
        currentProcessingId = id
        processingMessage = message
        processingProgress = 0.0
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isShowingProcessingBanner = true
        }
    }
    
    func updateProcessingProgress(_ progress: Double, message: String? = nil, id: UUID? = nil) {
        // Only update if this is for the current processing session
        if let processingId = id, processingId != currentProcessingId {
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            processingProgress = min(max(progress, 0.0), 1.0)
        }
        
        if let message = message {
            processingMessage = message
        }
        
        // Auto-hide when complete
        if processingProgress >= 1.0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.hideProcessingBanner()
            }
        }
    }
    
    func hideProcessingBanner() {
        withAnimation(.easeOut(duration: 0.3)) {
            isShowingProcessingBanner = false
        }
        
        processingTimer?.invalidate()
        currentProcessingId = nil
    }
    
    // MARK: - Quick Preview Methods
    func showQuickPreview(with data: PreviewData) {
        previewData = data
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            isShowingQuickPreview = true
        }
        
        // Auto-hide after 8 seconds
        autoHideTimer?.invalidate()
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: false) { _ in
            Task { @MainActor in
                self.hideQuickPreview()
            }
        }
    }
    
    func hideQuickPreview() {
        withAnimation(.easeOut(duration: 0.3)) {
            isShowingQuickPreview = false
        }
        
        autoHideTimer?.invalidate()
        
        // Clear data after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.previewData = nil
        }
    }
    
    func handleQuickAction(_ action: QuickAction) {
        hideQuickPreview()
        
        // Perform the requested action
        switch action {
        case .save:
            showSuccessToast("Content saved to favorites", details: "Added to your favorites collection")
            
        case .createTasks:
            if let taskCount = previewData?.suggestedTasksCount, taskCount > 0 {
                showSuccessToast("Tasks created", details: "Created \(taskCount) intelligent task\(taskCount == 1 ? "" : "s")")
            } else {
                showSuccessToast("Tasks analyzed", details: "No actionable tasks found in this content")
            }
            
        case .share:
            showSuccessToast("Content shared", details: "Share sheet opened")
            
        case .viewDetails:
            // Navigate to content details
            break
        }
    }
    
    // MARK: - Success Toast Methods
    func showSuccessToast(_ message: String, details: String? = nil) {
        successMessage = message
        successDetails = details
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isShowingSuccessToast = true
        }
        
        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.hideSuccessToast()
        }
    }
    
    func hideSuccessToast() {
        withAnimation(.easeOut(duration: 0.3)) {
            isShowingSuccessToast = false
        }
    }
    
    // MARK: - Magic Moment Methods
    func showMagicMoment(message: String, details: String) {
        magicMomentData = MagicMomentData(message: message, details: details)
        
        withAnimation(.easeInOut(duration: 0.6)) {
            isShowingMagicMoment = true
        }
    }
    
    func hideMagicMoment() {
        withAnimation(.easeOut(duration: 0.4)) {
            isShowingMagicMoment = false
        }
        
        // Clear data after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.magicMomentData = nil
        }
    }
    
    // MARK: - Convenience Methods
    func showContentProcessingFlow(for contentType: ContentType) {
        let processingId = UUID()
        
        // Step 1: Show processing banner
        showProcessingBanner(message: "🧠 AI is analyzing your \(contentType.displayName.lowercased())...", id: processingId)
        
        // Simulate processing steps with progress updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateProcessingProgress(0.3, message: "📝 Extracting text and content...", id: processingId)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.updateProcessingProgress(0.6, message: "🔍 Analyzing semantic meaning...", id: processingId)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.updateProcessingProgress(0.8, message: "⚡ Generating intelligent tasks...", id: processingId)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            self.updateProcessingProgress(1.0, message: "✅ Processing complete!", id: processingId)
        }
    }
    
    func showSuccessfulCaptureFlow(previewData: PreviewData) {
        // Step 1: Magic moment
        showMagicMoment(
            message: "✨ Content Captured!",
            details: "AI extracted insights and created actionable items"
        )
        
        // Step 2: Show preview after magic moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.showQuickPreview(with: previewData)
        }
    }
    
    // MARK: - Integration with Content Processing
    func connectToContentProcessor(_ processor: ContentCaptureProcessor) {
        // Observe processing state
        processor.$isProcessing
            .sink { [weak self] isProcessing in
                guard let self = self else { return }
                
                if !isProcessing && self.isShowingProcessingBanner {
                    // Processing completed
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.hideProcessingBanner()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Observe processing progress
        processor.$processingProgress
            .sink { [weak self] progress in
                guard let self = self else { return }
                
                if self.isShowingProcessingBanner {
                    let message = self.getProgressMessage(for: progress)
                    self.updateProcessingProgress(progress, message: message)
                }
            }
            .store(in: &cancellables)
    }
    
    private func getProgressMessage(for progress: Double) -> String {
        switch progress {
        case 0.0..<0.2:
            return "🔍 Analyzing image content..."
        case 0.2..<0.5:
            return "📝 Extracting text with OCR..."
        case 0.5..<0.8:
            return "🧠 Understanding semantic meaning..."
        case 0.8..<1.0:
            return "⚡ Creating intelligent tasks..."
        default:
            return "✅ Processing complete!"
        }
    }
    
    // MARK: - Haptic Feedback
    private func triggerHapticFeedback(for type: FeedbackType) {
        let impact: UIImpactFeedbackGenerator
        
        switch type {
        case .light:
            impact = UIImpactFeedbackGenerator(style: .light)
        case .medium:
            impact = UIImpactFeedbackGenerator(style: .medium)
        case .heavy:
            impact = UIImpactFeedbackGenerator(style: .heavy)
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        
        impact.impactOccurred()
    }
    
    // MARK: - Cleanup
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        processingTimer?.invalidate()
        autoHideTimer?.invalidate()
        cancellables.removeAll()
    }
}

// MARK: - Supporting Models
struct PreviewData {
    let title: String
    let preview: String
    let contentType: ContentType
    let extractedInsights: [String]
    let suggestedTasksCount: Int
    let confidence: Double
    let processingTime: TimeInterval
    
    init(from contentItem: ContentItem, insights: [String] = [], taskCount: Int = 0, confidence: Double = 0.85, processingTime: TimeInterval = 2.0) {
        self.title = contentItem.title
        self.preview = contentItem.preview
        self.contentType = contentItem.type
        self.extractedInsights = insights
        self.suggestedTasksCount = taskCount
        self.confidence = confidence
        self.processingTime = processingTime
    }
}

struct MagicMomentData {
    let message: String
    let details: String
}

enum QuickAction {
    case save
    case createTasks
    case share
    case viewDetails
}

enum FeedbackType {
    case light, medium, heavy
    case success, warning, error
}

// MARK: - Preview Helpers
extension PreviewData {
    static var sampleData: PreviewData {
        PreviewData(
            from: ContentItem.sampleData.first!,
            insights: [
                "Meeting scheduled for next Tuesday",
                "3 action items identified",
                "Contact information extracted"
            ],
            taskCount: 3,
            confidence: 0.92,
            processingTime: 1.8
        )
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let contentProcessingStarted = Notification.Name("contentProcessingStarted")
    static let contentProcessingCompleted = Notification.Name("contentProcessingCompleted")
    static let screenshotCaptured = Notification.Name("screenshotCaptured")
}