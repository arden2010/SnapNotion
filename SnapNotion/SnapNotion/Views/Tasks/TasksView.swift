//
//  TasksView.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI

struct TasksView: View {
    @State private var tasks: [SimpleTaskItem] = SimpleTaskItem.sampleTasks
    @State private var showingCompleted = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Toggle for completed tasks
                HStack {
                    Toggle("Show Completed", isOn: $showingCompleted)
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Tasks List
                if displayedTasks.isEmpty {
                    TasksEmptyState(showingCompleted: showingCompleted)
                } else {
                    List {
                        ForEach(displayedTasks) { task in
                            TaskRowView(task: task) { updatedTask in
                                if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                                    tasks[index] = updatedTask
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                Spacer()
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        // TODO: Implement add task
                        addSampleTask()
                    }
                }
            }
        }
    }
    
    private var pendingTasks: [SimpleTaskItem] {
        tasks.filter { !$0.isCompleted }
    }
    
    private var displayedTasks: [SimpleTaskItem] {
        if showingCompleted {
            return tasks
        } else {
            return pendingTasks
        }
    }
    
    private func addSampleTask() {
        let newTask = SimpleTaskItem(
            title: "New Task",
            description: "Generated from content analysis",
            isCompleted: false,
            priority: .medium,
            dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
        )
        tasks.insert(newTask, at: 0)
    }
}

struct SimpleTaskItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    var isCompleted: Bool
    let priority: TaskPriority
    let dueDate: Date?
    let createdAt: Date = Date()
    
    enum TaskPriority: String, CaseIterable {
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .green
            }
        }
    }
    
    static let sampleTasks: [SimpleTaskItem] = [
        // Urgent/Overdue tasks
        SimpleTaskItem(
            title: "Review Q4 planning meeting notes", 
            description: "Extract action items and decisions from the planning session", 
            isCompleted: false, 
            priority: .high, 
            dueDate: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) // 2 hours overdue
        ),
        SimpleTaskItem(
            title: "Respond to customer feedback", 
            description: "Address user feedback about search functionality improvements", 
            isCompleted: false, 
            priority: .high, 
            dueDate: Date().addingTimeInterval(3600) // 1 hour from now
        ),
        
        // Due today
        SimpleTaskItem(
            title: "Implement SwiftUI grid layout", 
            description: "Apply best practices from the captured article to our interface", 
            isCompleted: false, 
            priority: .medium, 
            dueDate: Date().addingTimeInterval(14400) // 4 hours from now
        ),
        SimpleTaskItem(
            title: "Test authentication module", 
            description: "Add unit tests for edge cases mentioned in code review", 
            isCompleted: false, 
            priority: .medium, 
            dueDate: Date().addingTimeInterval(21600) // 6 hours from now
        ),
        
        // Due tomorrow
        SimpleTaskItem(
            title: "Update app store screenshots", 
            description: "Use new dashboard design for promotional materials", 
            isCompleted: false, 
            priority: .medium, 
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())
        ),
        SimpleTaskItem(
            title: "Analyze competitor research", 
            description: "Review market research report findings and create action plan", 
            isCompleted: false, 
            priority: .low, 
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())
        ),
        
        // Due this week
        SimpleTaskItem(
            title: "Prepare design system documentation", 
            description: "Compile design guidelines for the development team", 
            isCompleted: false, 
            priority: .medium, 
            dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())
        ),
        SimpleTaskItem(
            title: "Optimize API performance", 
            description: "Implement improvements mentioned in team standup", 
            isCompleted: false, 
            priority: .low, 
            dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())
        ),
        
        // Completed tasks
        SimpleTaskItem(
            title: "Fix sync bug", 
            description: "Resolved synchronization issues reported by users", 
            isCompleted: true, 
            priority: .high, 
            dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())
        ),
        SimpleTaskItem(
            title: "Complete user testing", 
            description: "Achieved 87% satisfaction rate in usability testing", 
            isCompleted: true, 
            priority: .medium, 
            dueDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())
        ),
        SimpleTaskItem(
            title: "Research React vs SwiftUI", 
            description: "Compare performance metrics for technology decision", 
            isCompleted: true, 
            priority: .low, 
            dueDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())
        )
    ]
}

struct TasksEmptyState: View {
    let showingCompleted: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: showingCompleted ? "checkmark.circle" : "list.bullet")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text(showingCompleted ? "No Completed Tasks" : "No Pending Tasks")
                .font(.title2)
                .fontWeight(.medium)
            
            Text(showingCompleted ? "Complete some tasks to see them here" : "AI will automatically generate tasks from your captured content")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TaskRowView: View {
    let task: SimpleTaskItem
    let onUpdate: (SimpleTaskItem) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: toggleCompletion) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                
                Text(task.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(task.priority.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(task.priority.color.opacity(0.2))
                        .foregroundColor(task.priority.color)
                        .cornerRadius(4)
                    
                    if let dueDate = task.dueDate {
                        Text(dueDate, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
    
    private func toggleCompletion() {
        let updatedTask = SimpleTaskItem(
            title: task.title,
            description: task.description,
            isCompleted: !task.isCompleted,
            priority: task.priority,
            dueDate: task.dueDate
        )
        onUpdate(updatedTask)
    }
}

/*
#Preview {
    TasksView()
}
*/