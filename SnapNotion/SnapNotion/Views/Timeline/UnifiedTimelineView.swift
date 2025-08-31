//
//  UnifiedTimelineView.swift
//  SnapNotion
//
//  Created by A. C. on 8/31/25.
//

import SwiftUI

struct UnifiedTimelineView: View {
    @StateObject private var timelineManager = TimelineManager()
    @State private var selectedFilter: TimelineFilter = .all
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Tabs
                TimelineFilterTabs(selectedFilter: $selectedFilter)
                
                // Timeline Content
                if timelineManager.isLoading {
                    ProgressView("Loading timeline...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredItems.isEmpty {
                    TimelineEmptyState(filter: selectedFilter)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(groupedByDate.keys.sorted(by: >)), id: \.self) { date in
                                TimelineDateSection(
                                    date: date,
                                    items: groupedByDate[date] ?? []
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 100) // Space for FAB
                    }
                }
            }
            .navigationTitle("Timeline")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            timelineManager.loadTimelineItems()
        }
    }
    
    // MARK: - Computed Properties
    private var filteredItems: [UnifiedTimelineItem] {
        switch selectedFilter {
        case .all:
            return timelineManager.timelineItems
        case .content:
            return timelineManager.timelineItems.filter { $0.timelineType == .content }
        case .tasks:
            return timelineManager.timelineItems.filter { $0.timelineType == .task }
        case .completed:
            return timelineManager.timelineItems.filter { $0.isCompleted }
        case .favorites:
            return timelineManager.timelineItems.filter { $0.isFavorite }
        }
    }
    
    private var groupedByDate: [Date: [UnifiedTimelineItem]] {
        Dictionary(grouping: filteredItems) { item in
            Calendar.current.startOfDay(for: item.timestamp)
        }
    }
}

// MARK: - Timeline Filter
enum TimelineFilter: String, CaseIterable {
    case all = "all"
    case content = "content"
    case tasks = "tasks"
    case completed = "completed"
    case favorites = "favorites"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .content: return "Content"
        case .tasks: return "Tasks"
        case .completed: return "Done"
        case .favorites: return "Starred"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .content: return "doc.text"
        case .tasks: return "checkmark.circle"
        case .completed: return "checkmark.circle.fill"
        case .favorites: return "star.fill"
        }
    }
}

// MARK: - Filter Tabs
struct TimelineFilterTabs: View {
    @Binding var selectedFilter: TimelineFilter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TimelineFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: filter.icon)
                                .font(.caption)
                            Text(filter.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedFilter == filter ? Color.phoenixOrange : Color(.systemGray6))
                        )
                        .foregroundColor(selectedFilter == filter ? .white : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

// MARK: - Date Section
struct TimelineDateSection: View {
    let date: Date
    let items: [UnifiedTimelineItem]
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateStyle = .none
            return formatter
        } else if Calendar.current.isDateInYesterday(date) {
            formatter.dateStyle = .none
            return formatter
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter
        }
    }
    
    private var displayDate: String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return dateFormatter.string(from: date)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Date Header
            HStack {
                Text(displayDate)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(items.count) item\(items.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
            .padding(.top, 16) // Add top padding for section
            
            // Timeline Items
            VStack(spacing: 12) {
                ForEach(items.sorted(by: { $0.timestamp > $1.timestamp })) { item in
                    TimelineItemRow(item: item)
                }
            }
        }
    }
}

// MARK: - Timeline Item Row
struct TimelineItemRow: View {
    let item: UnifiedTimelineItem
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Timeline indicator
            VStack {
                ZStack {
                    Circle()
                        .fill(item.timelineType.color.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : item.timelineType.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(item.isCompleted ? .green : item.timelineType.color)
                }
                
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 2)
                    .frame(minHeight: 20)
                
                Spacer()
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(item.isCompleted ? .secondary : .primary)
                            .strikethrough(item.isCompleted)
                            .lineLimit(2)
                        
                        Text(item.subtitle)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(timeFormatter.string(from: item.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if item.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                }
                
                // Metadata
                HStack(spacing: 8) {
                    // Type badge
                    HStack(spacing: 4) {
                        Image(systemName: item.timelineType.icon)
                            .font(.caption2)
                        Text(item.timelineType.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(item.timelineType.color.opacity(0.1))
                    .foregroundColor(item.timelineType.color)
                    .cornerRadius(8)
                    
                    // Priority badge (for tasks)
                    if item.timelineType == .task && item.priority != .low {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(item.priority.color)
                                .frame(width: 6, height: 6)
                            Text(item.priority.displayName)
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(item.priority.color.opacity(0.1))
                        .foregroundColor(item.priority.color)
                        .cornerRadius(8)
                    }
                    
                    // Due date (for tasks)
                    if let dueDate = item.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(dueDate, style: .date)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray6))
                        .foregroundColor(.secondary)
                        .cornerRadius(8)
                    }
                    
                    // Content source (for content items)
                    if let sourceApp = item.sourceApp {
                        Text(sourceApp.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray6))
                            .foregroundColor(.secondary)
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .opacity(item.isCompleted ? 0.7 : 1.0)
    }
}

// MARK: - Empty State
struct TimelineEmptyState: View {
    let filter: TimelineFilter
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "timeline")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text(emptyStateTitle)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(emptyStateMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateTitle: String {
        switch filter {
        case .all: return "No Items Yet"
        case .content: return "No Content Yet"
        case .tasks: return "No Tasks Yet"
        case .completed: return "No Completed Items"
        case .favorites: return "No Favorites Yet"
        }
    }
    
    private var emptyStateMessage: String {
        switch filter {
        case .all: return "Your timeline will show all content and tasks as you create them"
        case .content: return "Capture content using the smart FAB button"
        case .tasks: return "Tasks will appear here as they're created from your content"
        case .completed: return "Completed items will appear here"
        case .favorites: return "Items you mark as favorites will appear here"
        }
    }
}

#Preview {
    UnifiedTimelineView()
}