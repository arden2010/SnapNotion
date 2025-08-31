//
//  TimelineModels.swift
//  SnapNotion
//
//  Created by A. C. on 8/31/25.
//

import Foundation
import SwiftUI

// MARK: - Timeline Item Protocol
protocol TimelineItem: Identifiable {
    var id: UUID { get }
    var title: String { get }
    var subtitle: String { get }
    var timestamp: Date { get }
    var timelineType: TimelineItemType { get }
    var priority: TimelinePriority { get }
    var isCompleted: Bool { get }
}

// MARK: - Timeline Item Type
enum TimelineItemType: String, CaseIterable {
    case content = "content"
    case task = "task"
    case note = "note"
    case event = "event"
    
    var displayName: String {
        switch self {
        case .content: return "Content"
        case .task: return "Task"
        case .note: return "Note"
        case .event: return "Event"
        }
    }
    
    var icon: String {
        switch self {
        case .content: return "doc.text"
        case .task: return "checkmark.circle"
        case .note: return "note.text"
        case .event: return "calendar"
        }
    }
    
    var color: Color {
        switch self {
        case .content: return .blue
        case .task: return .phoenixOrange
        case .note: return .green
        case .event: return .purple
        }
    }
}

// MARK: - Timeline Priority
enum TimelinePriority: Int, CaseIterable, Comparable {
    case low = 0
    case medium = 1
    case high = 2
    case urgent = 3
    
    static func < (lhs: TimelinePriority, rhs: TimelinePriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .urgent: return .red
        }
    }
}

// MARK: - Unified Timeline Item
struct UnifiedTimelineItem: TimelineItem, Equatable {
    let id: UUID
    let title: String
    let subtitle: String
    let timestamp: Date
    let timelineType: TimelineItemType
    let priority: TimelinePriority
    let isCompleted: Bool
    let sourceObject: Any // Original ContentItem or SimpleTaskItem
    
    // Content-specific properties
    let contentType: ContentType?
    let sourceApp: AppSource?
    let isFavorite: Bool
    
    // Task-specific properties
    let dueDate: Date?
    let taskPriority: SimpleTaskItem.TaskPriority?
    
    init(from contentItem: ContentItem) {
        self.id = contentItem.id
        self.title = contentItem.title
        self.subtitle = contentItem.preview
        self.timestamp = contentItem.timestamp
        self.timelineType = .content
        self.priority = .medium // Default priority for content
        self.isCompleted = false
        self.sourceObject = contentItem
        
        // Content-specific
        self.contentType = contentItem.type
        self.sourceApp = contentItem.sourceApp
        self.isFavorite = contentItem.isFavorite
        
        // Task-specific (nil for content)
        self.dueDate = nil
        self.taskPriority = nil
    }
    
    init(from taskItem: SimpleTaskItem) {
        self.id = taskItem.id
        self.title = taskItem.title
        self.subtitle = taskItem.description
        self.timestamp = taskItem.createdAt
        self.timelineType = .task
        self.priority = TimelinePriority(from: taskItem.priority)
        self.isCompleted = taskItem.isCompleted
        self.sourceObject = taskItem
        
        // Content-specific (nil for tasks)
        self.contentType = nil
        self.sourceApp = nil
        self.isFavorite = false
        
        // Task-specific
        self.dueDate = taskItem.dueDate
        self.taskPriority = taskItem.priority
    }
    
    // MARK: - Equatable Implementation
    static func == (lhs: UnifiedTimelineItem, rhs: UnifiedTimelineItem) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Priority Conversion
extension TimelinePriority {
    init(from taskPriority: SimpleTaskItem.TaskPriority) {
        switch taskPriority {
        case .low:
            self = .low
        case .medium:
            self = .medium
        case .high:
            self = .high
        }
    }
}

// MARK: - Timeline Manager
@MainActor
class TimelineManager: ObservableObject {
    @Published var timelineItems: [UnifiedTimelineItem] = []
    @Published var isLoading = false
    
    private let contentViewModel = ContentViewModel()
    
    func loadTimelineItems() {
        isLoading = true
        
        // Load sample data - in real app, this would come from persistent storage
        let contentItems = sampleContentItems
        let taskItems = SimpleTaskItem.sampleTasks
        
        // Convert to unified timeline items
        var unifiedItems: [UnifiedTimelineItem] = []
        
        // Add content items
        for contentItem in contentItems {
            unifiedItems.append(UnifiedTimelineItem(from: contentItem))
        }
        
        // Add task items
        for taskItem in taskItems {
            unifiedItems.append(UnifiedTimelineItem(from: taskItem))
        }
        
        // Sort by timestamp (most recent first)
        unifiedItems.sort { $0.timestamp > $1.timestamp }
        
        self.timelineItems = unifiedItems
        isLoading = false
    }
    
    func addContentItem(_ contentItem: ContentItem) {
        let timelineItem = UnifiedTimelineItem(from: contentItem)
        timelineItems.insert(timelineItem, at: 0) // Add at beginning (most recent)
    }
    
    func addTaskItem(_ taskItem: SimpleTaskItem) {
        let timelineItem = UnifiedTimelineItem(from: taskItem)
        timelineItems.insert(timelineItem, at: 0) // Add at beginning (most recent)
    }
    
    func toggleTaskCompletion(_ taskId: UUID) {
        if let index = timelineItems.firstIndex(where: { $0.id == taskId && $0.timelineType == .task }) {
            let item = timelineItems[index]
            
            // Create updated item with toggled completion status
            var updatedItem = item
            // Note: Since UnifiedTimelineItem properties are let constants, we need to recreate it
            // In a real implementation, you'd update the source object and reload
            print("Toggle completion for task: \(item.title)")
        }
    }
}

// MARK: - Sample Data
private let sampleContentItems: [ContentItem] = [
    ContentItem(
        title: "SwiftUI Best Practices Guide",
        preview: "Comprehensive guide covering SwiftUI architecture patterns, state management, and performance optimization techniques...",
        source: "Apple Developer Documentation",
        sourceApp: .safari,
        type: .web,
        isFavorite: true,
        timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
    ),
    ContentItem(
        title: "Meeting Notes - Product Roadmap",
        preview: "Discussed Q4 features: advanced AI integration, knowledge graph improvements, cross-platform sync...",
        source: "Screenshot",
        sourceApp: .camera,
        type: .mixed,
        timestamp: Calendar.current.date(byAdding: .hour, value: -4, to: Date()) ?? Date()
    ),
    ContentItem(
        title: "Research Paper - Graph Algorithms",
        preview: "Implementation of efficient graph traversal algorithms for knowledge management systems...",
        source: "Academic PDF",
        sourceApp: .other,
        type: .pdf,
        timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    ),
    ContentItem(
        title: "Design Inspiration",
        preview: "Beautiful UI patterns for timeline interfaces, with emphasis on readability and interaction design...",
        source: "Dribbble",
        sourceApp: .safari,
        type: .image,
        isFavorite: true,
        timestamp: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
    ),
    ContentItem(
        title: "Code Review Feedback",
        preview: "Detailed feedback on the advanced AI implementation, including performance optimizations and error handling improvements...",
        source: "Clipboard",
        sourceApp: .clipboard,
        type: .text,
        timestamp: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
    )
]