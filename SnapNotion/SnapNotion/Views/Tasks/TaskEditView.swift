//
//  TaskEditView.swift
//  SnapNotion
//
//  Task editing interface for modifying task details
//  Created by A. C. on 9/9/25.
//

import SwiftUI

struct TaskEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var description: String
    @State private var priority: SimpleTaskItem.TaskPriority
    @State private var dueDate: Date?
    @State private var hasDueDate: Bool
    
    let task: SimpleTaskItem
    let onSave: (SimpleTaskItem) -> Void
    
    init(task: SimpleTaskItem, onSave: @escaping (SimpleTaskItem) -> Void) {
        self.task = task
        self.onSave = onSave
        
        // Initialize state
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description)
        _priority = State(initialValue: task.priority)
        _dueDate = State(initialValue: task.dueDate)
        _hasDueDate = State(initialValue: task.dueDate != nil)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                        .font(.headline)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(SimpleTaskItem.TaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(priority.color)
                                    .frame(width: 12, height: 12)
                                Text(priority.rawValue)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)
                        .tint(.phoenixOrange)
                    
                    if hasDueDate {
                        DatePicker("Due date", selection: Binding(
                            get: { dueDate ?? Date() },
                            set: { dueDate = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                    }
                }
                
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Text("Created")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(task.createdAt, style: .date)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Text("Status")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(task.isCompleted ? "Completed" : "Pending")
                                .font(.caption2)
                                .foregroundColor(task.isCompleted ? .green : .orange)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveTask() {
        let updatedTask = SimpleTaskItem(
            id: task.id, // Preserve original ID
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            isCompleted: task.isCompleted, // Preserve completion status
            priority: priority,
            dueDate: hasDueDate ? dueDate : nil,
            createdAt: task.createdAt // Preserve creation date
        )
        onSave(updatedTask)
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    TaskEditView(task: SimpleTaskItem.sampleTasks.first!) { updatedTask in
        print("Updated task: \(updatedTask.title)")
    }
}