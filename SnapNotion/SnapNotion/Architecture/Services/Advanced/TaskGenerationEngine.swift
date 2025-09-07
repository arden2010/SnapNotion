//
//  TaskGenerationEngine.swift
//  SnapNotion
//
//  Intelligent task generation from captured content using AI analysis
//  Created by A. C. on 9/7/25.
//

import Foundation
import NaturalLanguage
import SwiftUI
import os.log

@MainActor
class TaskGenerationEngine: ObservableObject {
    
    static let shared = TaskGenerationEngine()
    
    @Published var isGeneratingTasks = false
    @Published var generatedTasks: [AIGeneratedTask] = []
    @Published var taskSuggestions: [TaskSuggestion] = []
    
    private let logger = Logger(subsystem: "com.snapnotion.tasks", category: "TaskGenerator")
    private let aiAnalyzer = AIContentAnalyzer.shared
    
    // Advanced task patterns and their corresponding actions
    private let taskPatterns: [TaskPattern] = [
        TaskPattern(
            keywords: ["call", "phone", "contact"],
            action: "Make a call",
            priority: .medium,
            dueOffset: .hours(2),
            category: .communication
        ),
        TaskPattern(
            keywords: ["email", "send", "reply", "respond"],
            action: "Send email",
            priority: .medium,
            dueOffset: .days(1),
            category: .communication
        ),
        TaskPattern(
            keywords: ["meeting", "schedule", "appointment"],
            action: "Schedule meeting",
            priority: .high,
            dueOffset: .hours(4),
            category: .scheduling
        ),
        TaskPattern(
            keywords: ["buy", "purchase", "order", "shopping"],
            action: "Make purchase",
            priority: .low,
            dueOffset: .days(3),
            category: .shopping
        ),
        TaskPattern(
            keywords: ["review", "check", "analyze", "evaluate"],
            action: "Review content",
            priority: .medium,
            dueOffset: .days(2),
            category: .analysis
        ),
        TaskPattern(
            keywords: ["deadline", "due", "submit"],
            action: "Complete task",
            priority: .high,
            dueOffset: .hours(12),
            category: .deadline
        ),
        TaskPattern(
            keywords: ["book", "reserve", "appointment"],
            action: "Make reservation",
            priority: .medium,
            dueOffset: .days(1),
            category: .scheduling
        ),
        TaskPattern(
            keywords: ["follow up", "follow-up", "followup"],
            action: "Follow up",
            priority: .medium,
            dueOffset: .days(7),
            category: .communication
        )
    ]
    
    // MARK: - Core Task Generation
    
    func generateTasksFromContent(_ content: ContentNodeData) async throws -> [AIGeneratedTask] {
        isGeneratingTasks = true
        defer { isGeneratingTasks = false }
        
        logger.info("Generating tasks from content: \(content.id)")
        
        // Get AI analysis
        let analysis = try await aiAnalyzer.analyzeContent(content)
        
        var tasks: [AIGeneratedTask] = []
        
        // 1. Pattern-based task generation
        tasks.append(contentsOf: generatePatternBasedTasks(content, analysis: analysis))
        
        // 2. Action item extraction
        tasks.append(contentsOf: convertActionItemsToTasks(analysis.actionItems, sourceContent: content))
        
        // 3. Suggested task enhancement
        tasks.append(contentsOf: enhanceSuggestedTasks(analysis.suggestedTasks, sourceContent: content))
        
        // 4. Context-aware task generation
        tasks.append(contentsOf: generateContextAwareTasks(content, analysis: analysis))
        
        // 5. Time-sensitive task detection
        tasks.append(contentsOf: generateTimeSensitiveTasks(content, analysis: analysis))
        
        // Remove duplicates and rank by relevance
        let uniqueTasks = removeDuplicateTasks(tasks)
        let rankedTasks = rankTasksByRelevance(uniqueTasks, analysis: analysis)
        
        // Store generated tasks
        generatedTasks = rankedTasks
        
        logger.info("Generated \(rankedTasks.count) tasks from content")
        return Array(rankedTasks.prefix(10)) // Limit to top 10 tasks
    }
    
    func generateSmartTaskSuggestions(for content: ContentNodeData) async -> [SmartTaskSuggestion] {
        do {
            let analysis = try await aiAnalyzer.analyzeContent(content)
            let tasks = try await generateTasksFromContent(content)
            
            return tasks.map { task in
                SmartTaskSuggestion(
                    title: task.title,
                    description: task.description,
                    estimatedDuration: estimateTaskDuration(task),
                    urgencyScore: calculateUrgencyScore(task, analysis: analysis),
                    complexity: assessTaskComplexity(task),
                    dependencies: findTaskDependencies(task, in: tasks),
                    suggestedSchedule: suggestOptimalSchedule(task),
                    automationPotential: assessAutomationPotential(task)
                )
            }
        } catch {
            logger.error("Failed to generate smart task suggestions: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Pattern-Based Task Generation
    
    private func generatePatternBasedTasks(_ content: ContentNodeData, analysis: ContentAnalysis) -> [AIGeneratedTask] {
        let text = content.contentText ?? ""
        let sentences = text.components(separatedBy: .init(charactersIn: ".!?\n"))
        var tasks: [AIGeneratedTask] = []
        
        for sentence in sentences {
            let lowerSentence = sentence.lowercased().trimmingCharacters(in: .whitespaces)
            guard !lowerSentence.isEmpty else { continue }
            
            for pattern in taskPatterns {
                let matchingKeywords = pattern.keywords.filter { lowerSentence.contains($0) }
                
                if !matchingKeywords.isEmpty {
                    let task = AIGeneratedTask(
                        title: generateTaskTitle(from: sentence, pattern: pattern),
                        description: enhanceTaskDescription(sentence, pattern: pattern),
                        priority: adjustPriorityByContext(pattern.priority, analysis: analysis),
                        category: pattern.category,
                        dueDate: calculateDueDate(pattern.dueOffset),
                        confidence: calculatePatternConfidence(matchingKeywords.count, totalKeywords: pattern.keywords.count),
                        sourceContentId: content.id,
                        sourceText: sentence,
                        generationMethod: .patternBased,
                        tags: extractTaskTags(from: sentence, pattern: pattern),
                        estimatedDuration: estimateDurationFromPattern(pattern),
                        context: extractTaskContext(from: content, analysis: analysis)
                    )
                    tasks.append(task)
                    break // Only match one pattern per sentence
                }
            }
        }
        
        return tasks
    }
    
    private func convertActionItemsToTasks(_ actionItems: [ActionItem], sourceContent: ContentNodeData) -> [AIGeneratedTask] {
        return actionItems.map { actionItem in
            AIGeneratedTask(
                title: actionItem.action.capitalized,
                description: actionItem.description,
                priority: .medium,
                category: categorizeAction(actionItem.action),
                dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                confidence: actionItem.confidence,
                sourceContentId: sourceContent.id,
                sourceText: actionItem.description,
                generationMethod: .actionExtraction,
                tags: [actionItem.action],
                estimatedDuration: .minutes(30),
                context: TaskContext(
                    sourceType: sourceContent.type,
                    sourceApp: sourceContent.source,
                    createdAt: sourceContent.timestamp
                )
            )
        }
    }
    
    private func enhanceSuggestedTasks(_ suggestedTasks: [SuggestedTask], sourceContent: ContentNodeData) -> [AIGeneratedTask] {
        return suggestedTasks.map { suggestedTask in
            AIGeneratedTask(
                title: suggestedTask.title,
                description: suggestedTask.description,
                priority: suggestedTask.priority,
                category: categorizeSuggestedTask(suggestedTask),
                dueDate: suggestedTask.dueDate ?? Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                confidence: suggestedTask.confidence,
                sourceContentId: sourceContent.id,
                sourceText: suggestedTask.description,
                generationMethod: .aiSuggested,
                tags: extractTagsFromSuggestedTask(suggestedTask),
                estimatedDuration: .hours(1),
                context: TaskContext(
                    sourceType: sourceContent.type,
                    sourceApp: sourceContent.source,
                    createdAt: sourceContent.timestamp
                )
            )
        }
    }
    
    private func generateContextAwareTasks(_ content: ContentNodeData, analysis: ContentAnalysis) -> [AIGeneratedTask] {
        var tasks: [AIGeneratedTask] = []
        
        // Category-specific task generation
        switch analysis.category {
        case .business:
            tasks.append(contentsOf: generateBusinessTasks(content, analysis: analysis))
        case .personal:
            tasks.append(contentsOf: generatePersonalTasks(content, analysis: analysis))
        case .learning:
            tasks.append(contentsOf: generateLearningTasks(content, analysis: analysis))
        case .reference:
            tasks.append(contentsOf: generateReferenceTasks(content, analysis: analysis))
        case .task:
            // Content is already task-focused
            break
        case .entertainment:
            // Minimal task generation for entertainment
            break
        }
        
        return tasks
    }
    
    private func generateTimeSensitiveTasks(_ content: ContentNodeData, analysis: ContentAnalysis) -> [AIGeneratedTask] {
        var tasks: [AIGeneratedTask] = []
        let text = content.contentText ?? ""
        
        // Time expressions and their corresponding urgencies
        let timeExpressions = [
            ("today", TaskPriority.high, Calendar.Component.hour, 2),
            ("tomorrow", TaskPriority.high, Calendar.Component.hour, 8),
            ("this week", TaskPriority.medium, Calendar.Component.day, 2),
            ("next week", TaskPriority.medium, Calendar.Component.day, 7),
            ("asap", TaskPriority.high, Calendar.Component.hour, 1),
            ("urgent", TaskPriority.high, Calendar.Component.hour, 2)
        ]
        
        for (expression, priority, component, value) in timeExpressions {
            if text.lowercased().contains(expression) {
                let task = AIGeneratedTask(
                    title: "Time-sensitive: \(expression)",
                    description: "Handle time-sensitive content: \(String(text.prefix(100)))",
                    priority: priority,
                    category: .deadline,
                    dueDate: Calendar.current.date(byAdding: component, value: value, to: Date()),
                    confidence: 0.8,
                    sourceContentId: content.id,
                    sourceText: text,
                    generationMethod: .timeSensitive,
                    tags: ["urgent", expression],
                    estimatedDuration: .minutes(45),
                    context: TaskContext(
                        sourceType: content.type,
                        sourceApp: content.source,
                        createdAt: content.timestamp
                    )
                )
                tasks.append(task)
                break // Only one time-sensitive task per content
            }
        }
        
        return tasks
    }
    
    // MARK: - Task Enhancement Methods
    
    private func generateBusinessTasks(_ content: ContentNodeData, analysis: ContentAnalysis) -> [AIGeneratedTask] {
        var tasks: [AIGeneratedTask] = []
        
        // Look for business-specific patterns
        let businessPatterns = ["project", "client", "proposal", "deadline", "budget", "meeting"]
        let text = content.contentText?.lowercased() ?? ""
        
        for pattern in businessPatterns where text.contains(pattern) {
            let task = AIGeneratedTask(
                title: "Business: \(pattern.capitalized) follow-up",
                description: "Follow up on \(pattern) mentioned in content",
                priority: .medium,
                category: .business,
                dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
                confidence: 0.7,
                sourceContentId: content.id,
                sourceText: content.contentText ?? "",
                generationMethod: .contextAware,
                tags: ["business", pattern],
                estimatedDuration: .hours(1),
                context: TaskContext(
                    sourceType: content.type,
                    sourceApp: content.source,
                    createdAt: content.timestamp
                )
            )
            tasks.append(task)
        }
        
        return tasks
    }
    
    private func generatePersonalTasks(_ content: ContentNodeData, analysis: ContentAnalysis) -> [AIGeneratedTask] {
        var tasks: [AIGeneratedTask] = []
        
        let personalPatterns = ["appointment", "shopping", "health", "family", "home"]
        let text = content.contentText?.lowercased() ?? ""
        
        for pattern in personalPatterns where text.contains(pattern) {
            let task = AIGeneratedTask(
                title: "Personal: \(pattern.capitalized) task",
                description: "Handle \(pattern) item from captured content",
                priority: .low,
                category: .personal,
                dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
                confidence: 0.6,
                sourceContentId: content.id,
                sourceText: content.contentText ?? "",
                generationMethod: .contextAware,
                tags: ["personal", pattern],
                estimatedDuration: .minutes(30),
                context: TaskContext(
                    sourceType: content.type,
                    sourceApp: content.source,
                    createdAt: content.timestamp
                )
            )
            tasks.append(task)
        }
        
        return tasks
    }
    
    private func generateLearningTasks(_ content: ContentNodeData, analysis: ContentAnalysis) -> [AIGeneratedTask] {
        let task = AIGeneratedTask(
            title: "Review learning material",
            description: "Review and study the captured learning content",
            priority: .medium,
            category: .learning,
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
            confidence: 0.8,
            sourceContentId: content.id,
            sourceText: content.contentText ?? "",
            generationMethod: .contextAware,
            tags: ["learning", "review"],
            estimatedDuration: .minutes(45),
            context: TaskContext(
                sourceType: content.type,
                sourceApp: content.source,
                createdAt: content.timestamp
            )
        )
        
        return [task]
    }
    
    private func generateReferenceTasks(_ content: ContentNodeData, analysis: ContentAnalysis) -> [AIGeneratedTask] {
        let task = AIGeneratedTask(
            title: "Organize reference material",
            description: "File and organize the reference content for future use",
            priority: .low,
            category: .organization,
            dueDate: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()),
            confidence: 0.5,
            sourceContentId: content.id,
            sourceText: content.contentText ?? "",
            generationMethod: .contextAware,
            tags: ["reference", "organize"],
            estimatedDuration: .minutes(15),
            context: TaskContext(
                sourceType: content.type,
                sourceApp: content.source,
                createdAt: content.timestamp
            )
        )
        
        return [task]
    }
    
    // MARK: - Helper Methods
    
    private func removeDuplicateTasks(_ tasks: [AIGeneratedTask]) -> [AIGeneratedTask] {
        var seen = Set<String>()
        return tasks.filter { task in
            let key = task.title.lowercased() + task.category.rawValue
            if seen.contains(key) {
                return false
            }
            seen.insert(key)
            return true
        }
    }
    
    private func rankTasksByRelevance(_ tasks: [AIGeneratedTask], analysis: ContentAnalysis) -> [AIGeneratedTask] {
        return tasks.sorted { task1, task2 in
            // Ranking criteria: confidence, priority, recency
            let score1 = task1.confidence + (task1.priority == .high ? 0.3 : task1.priority == .medium ? 0.2 : 0.1)
            let score2 = task2.confidence + (task2.priority == .high ? 0.3 : task2.priority == .medium ? 0.2 : 0.1)
            return score1 > score2
        }
    }
    
    private func estimateTaskDuration(_ task: AIGeneratedTask) -> TaskDuration {
        // Smart duration estimation based on task characteristics
        switch task.category {
        case .communication:
            return .minutes(15)
        case .scheduling:
            return .minutes(10)
        case .shopping:
            return .hours(1)
        case .analysis:
            return .hours(2)
        case .deadline:
            return .hours(3)
        case .business:
            return .hours(1)
        case .personal:
            return .minutes(30)
        case .learning:
            return .hours(1)
        case .organization:
            return .minutes(20)
        }
    }
    
    private func calculateUrgencyScore(_ task: AIGeneratedTask, analysis: ContentAnalysis) -> Double {
        var score = 0.5
        
        // Priority boost
        switch task.priority {
        case .high: score += 0.3
        case .medium: score += 0.1
        case .low: break
        }
        
        // Due date proximity
        if let dueDate = task.dueDate {
            let timeUntilDue = dueDate.timeIntervalSinceNow
            if timeUntilDue < 3600 { // 1 hour
                score += 0.4
            } else if timeUntilDue < 86400 { // 1 day
                score += 0.2
            }
        }
        
        return min(score, 1.0)
    }
    
    private func assessTaskComplexity(_ task: AIGeneratedTask) -> TaskComplexity {
        let descriptionLength = task.description.count
        
        if descriptionLength < 50 {
            return .simple
        } else if descriptionLength < 150 {
            return .moderate
        } else {
            return .complex
        }
    }
    
    private func findTaskDependencies(_ task: AIGeneratedTask, in tasks: [AIGeneratedTask]) -> [UUID] {
        // Simple dependency detection based on related content
        return tasks.compactMap { otherTask in
            if otherTask.sourceContentId == task.sourceContentId && otherTask.id != task.id {
                return otherTask.id
            }
            return nil
        }
    }
    
    private func suggestOptimalSchedule(_ task: AIGeneratedTask) -> Date? {
        guard let dueDate = task.dueDate else { return nil }
        
        // Suggest scheduling based on estimated duration and urgency
        let timeBuffer = task.estimatedDuration.timeInterval * 1.5 // Add 50% buffer
        return Date(timeInterval: -timeBuffer, since: dueDate)
    }
    
    private func assessAutomationPotential(_ task: AIGeneratedTask) -> AutomationPotential {
        let automationKeywords = ["send", "email", "schedule", "reminder", "book", "order"]
        let hasAutomationKeywords = automationKeywords.contains { task.title.lowercased().contains($0) }
        
        return hasAutomationKeywords ? .high : .low
    }
    
    // Additional helper methods...
    private func generateTaskTitle(from sentence: String, pattern: TaskPattern) -> String {
        return "\(pattern.action): \(String(sentence.prefix(40)))"
    }
    
    private func enhanceTaskDescription(_ sentence: String, pattern: TaskPattern) -> String {
        return sentence.trimmingCharacters(in: .whitespaces)
    }
    
    private func adjustPriorityByContext(_ priority: TaskPriority, analysis: ContentAnalysis) -> TaskPriority {
        if analysis.priority == .high && priority != .high {
            return .medium
        }
        return priority
    }
    
    private func calculateDueDate(_ offset: TaskDurationOffset) -> Date? {
        let calendar = Calendar.current
        switch offset {
        case .hours(let hours):
            return calendar.date(byAdding: .hour, value: hours, to: Date())
        case .days(let days):
            return calendar.date(byAdding: .day, value: days, to: Date())
        }
    }
    
    private func calculatePatternConfidence(_ matchingKeywords: Int, totalKeywords: Int) -> Double {
        return Double(matchingKeywords) / Double(totalKeywords)
    }
    
    private func extractTaskTags(from sentence: String, pattern: TaskPattern) -> [String] {
        return pattern.keywords.filter { sentence.lowercased().contains($0) } + [pattern.category.rawValue]
    }
    
    private func extractTaskContext(from content: ContentNodeData, analysis: ContentAnalysis) -> TaskContext {
        return TaskContext(
            sourceType: content.type,
            sourceApp: content.source,
            createdAt: content.timestamp
        )
    }
    
    private func categorizeAction(_ action: String) -> TaskCategory {
        let communicationActions = ["call", "email", "send", "reply"]
        if communicationActions.contains(action.lowercased()) {
            return .communication
        }
        return .personal
    }
    
    private func categorizeSuggestedTask(_ task: SuggestedTask) -> TaskCategory {
        return .personal // Default categorization
    }
    
    private func extractTagsFromSuggestedTask(_ task: SuggestedTask) -> [String] {
        return ["suggested"]
    }
}

// MARK: - Supporting Data Models

struct AIAIGeneratedTask: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let priority: TaskPriority
    let category: TaskCategory
    let dueDate: Date?
    let confidence: Double
    let sourceContentId: UUID
    let sourceText: String
    let generationMethod: TaskGenerationMethod
    let tags: [String]
    let estimatedDuration: TaskDuration
    let context: TaskContext
}

struct TaskPattern {
    let keywords: [String]
    let action: String
    let priority: TaskPriority
    let dueOffset: TaskDurationOffset
    let category: TaskCategory
}

enum TaskDurationOffset {
    case hours(Int)
    case days(Int)
}

enum TaskCategory: String, CaseIterable, Codable {
    case communication = "communication"
    case scheduling = "scheduling"
    case shopping = "shopping"
    case analysis = "analysis"
    case deadline = "deadline"
    case business = "business"
    case personal = "personal"
    case learning = "learning"
    case organization = "organization"
}

enum TaskGenerationMethod: String, Codable {
    case patternBased = "pattern"
    case actionExtraction = "action"
    case aiSuggested = "ai"
    case contextAware = "context"
    case timeSensitive = "time"
}

enum TaskDuration: Codable {
    case minutes(Int)
    case hours(Int)
    
    var timeInterval: TimeInterval {
        switch self {
        case .minutes(let min):
            return TimeInterval(min * 60)
        case .hours(let hrs):
            return TimeInterval(hrs * 3600)
        }
    }
}

struct TaskContext: Codable {
    let sourceType: ContentType
    let sourceApp: String
    let createdAt: Date
}

struct SmartTaskSuggestion: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let estimatedDuration: TaskDuration
    let urgencyScore: Double
    let complexity: TaskComplexity
    let dependencies: [UUID]
    let suggestedSchedule: Date?
    let automationPotential: AutomationPotential
}

enum TaskComplexity: String, CaseIterable, Codable {
    case simple = "simple"
    case moderate = "moderate"
    case complex = "complex"
}

enum AutomationPotential: String, CaseIterable, Codable {
    case high = "high"
    case medium = "medium"
    case low = "low"
}