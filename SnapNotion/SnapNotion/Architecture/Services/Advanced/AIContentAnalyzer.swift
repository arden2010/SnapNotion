//
//  AIContentAnalyzer.swift
//  SnapNotion
//
//  AI-powered content analysis and semantic processing engine
//  Created by A. C. on 9/7/25.
//

import Foundation
import NaturalLanguage
import CoreML
import SwiftUI
import os.log

@MainActor
class AIContentAnalyzer: ObservableObject {
    
    static let shared = AIContentAnalyzer()
    
    private init() { }
    
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0.0
    
    private let logger = Logger(subsystem: "com.snapnotion.ai", category: "ContentAnalyzer")
    private let nlProcessor = NLLanguageRecognizer()
    private let sentimentAnalyzer = NLModel.sentimentClassifier()
    
    // MARK: - Core Analysis Pipeline
    
    func analyzeContent(_ content: ContentNodeData) async throws -> ContentAnalysis {
        isAnalyzing = true
        analysisProgress = 0.0
        defer { 
            isAnalyzing = false
            analysisProgress = 0.0
        }
        
        logger.info("Starting AI analysis for content: \(content.id)")
        
        // Step 1: Language Detection (20%)
        await updateProgress(0.2)
        let language = detectLanguage(content.contentText ?? "")
        
        // Step 2: Content Classification (40%)
        await updateProgress(0.4)
        let category = classifyContent(content)
        
        // Step 3: Semantic Analysis (60%)
        await updateProgress(0.6)
        let keywords = await extractKeywords(content.contentText ?? "")
        let entities = await extractEntities(content.contentText ?? "")
        
        // Step 4: Sentiment Analysis (80%)
        await updateProgress(0.8)
        let sentiment = analyzeSentiment(content.contentText ?? "")
        
        // Step 5: Task Generation (100%)
        await updateProgress(1.0)
        let suggestedTasks = await generateTasks(from: content)
        
        let analysis = ContentAnalysis(
            contentId: content.id,
            language: language,
            category: category,
            keywords: keywords,
            entities: entities,
            sentiment: sentiment,
            confidence: calculateConfidence(content, category: category),
            suggestedTags: generateTags(keywords: keywords, entities: entities, category: category),
            suggestedTasks: suggestedTasks,
            summary: await generateSummary(content.contentText ?? ""),
            actionItems: extractActionItems(content.contentText ?? ""),
            priority: assessPriority(content, sentiment: sentiment),
            analyzedAt: Date()
        )
        
        logger.info("AI analysis completed with confidence: \(analysis.confidence)")
        return analysis
    }
    
    // MARK: - Language Detection
    
    private func detectLanguage(_ text: String) -> String {
        guard !text.isEmpty else { return "unknown" }
        
        nlProcessor.processString(text)
        let language = nlProcessor.dominantLanguage?.rawValue ?? "en"
        return language
    }
    
    // MARK: - Content Classification
    
    private func classifyContent(_ content: ContentNodeData) -> AIContentCategory {
        let text = content.contentText ?? ""
        let title = content.title.lowercased()
        
        // Enhanced classification logic
        let businessKeywords = ["meeting", "project", "deadline", "budget", "revenue", "client", "proposal", "contract"]
        let personalKeywords = ["grocery", "shopping", "appointment", "reminder", "birthday", "vacation", "health"]
        let learningKeywords = ["course", "study", "learn", "tutorial", "research", "book", "article", "notes"]
        let taskKeywords = ["todo", "task", "complete", "finish", "do", "remember", "action", "urgent"]
        
        let combinedText = (title + " " + text).lowercased()
        
        // Count keyword matches
        let businessCount = businessKeywords.filter { combinedText.contains($0) }.count
        let personalCount = personalKeywords.filter { combinedText.contains($0) }.count
        let learningCount = learningKeywords.filter { combinedText.contains($0) }.count
        let taskCount = taskKeywords.filter { combinedText.contains($0) }.count
        
        // Determine category based on content type and keywords
        switch content.type {
        case .pdf:
            return learningCount > 0 ? .learning : .reference
        case .web:
            return businessCount > personalCount ? .business : .reference
        case .image:
            // Use OCR text for classification if available
            if let ocrText = content.ocrText, !ocrText.isEmpty {
                let ocrLower = ocrText.lowercased()
                let ocrBusinessCount = businessKeywords.filter { ocrLower.contains($0) }.count
                return ocrBusinessCount > 1 ? .business : .personal
            }
            return .personal
        case .text:
            // Use keyword frequency analysis
            let maxCount = max(businessCount, personalCount, learningCount, taskCount)
            if maxCount == 0 { return .personal }
            
            if taskCount == maxCount { return .task }
            if businessCount == maxCount { return .business }
            if learningCount == maxCount { return .learning }
            return .personal
        default:
            return .personal
        }
    }
    
    // MARK: - Keyword Extraction
    
    private func extractKeywords(_ text: String) async -> [String] {
        guard !text.isEmpty else { return [] }
        
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
        tagger.string = text
        
        var keywords: [String] = []
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther]
        
        // Extract nouns and named entities
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            let word = String(text[tokenRange])
            
            if let tag = tag {
                switch tag {
                case .noun, .otherWord:
                    if word.count > 3 && !isStopWord(word.lowercased()) {
                        keywords.append(word.lowercased())
                    }
                default:
                    break
                }
            }
            return true
        }
        
        // Return top 10 most frequent keywords
        let keywordCounts = Dictionary(keywords.map { ($0, 1) }, uniquingKeysWith: +)
        return Array(keywordCounts.sorted { $0.value > $1.value }.prefix(10).map { $0.key })
    }
    
    // MARK: - Named Entity Recognition
    
    private func extractEntities(_ text: String) async -> [NamedEntity] {
        guard !text.isEmpty else { return [] }
        
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        var entities: [NamedEntity] = []
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            if let tag = tag {
                let entityText = String(text[tokenRange])
                let entityType: AIEntityType
                
                switch tag {
                case .personalName:
                    entityType = .person
                case .placeName:
                    entityType = .location
                case .organizationName:
                    entityType = .organization
                default:
                    entityType = .other
                }
                
                entities.append(NamedEntity(
                    text: entityText,
                    type: entityType,
                    confidence: 0.8,
                    range: text.distance(from: text.startIndex, to: tokenRange.lowerBound)
                ))
            }
            return true
        }
        
        return entities
    }
    
    // MARK: - Sentiment Analysis
    
    private func analyzeSentiment(_ text: String) -> SentimentScore {
        guard !text.isEmpty else { return SentimentScore(positive: 0.5, negative: 0.5, neutral: 1.0) }
        
        // Using basic sentiment analysis - could be enhanced with CoreML model
        let positiveWords = ["good", "great", "excellent", "amazing", "wonderful", "perfect", "love", "like", "happy", "excited"]
        let negativeWords = ["bad", "terrible", "awful", "hate", "dislike", "sad", "angry", "frustrated", "disappointed", "worried"]
        
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let positiveCount = words.filter { positiveWords.contains($0) }.count
        let negativeCount = words.filter { negativeWords.contains($0) }.count
        let totalWords = words.count
        
        let positive = Double(positiveCount) / Double(max(totalWords, 1))
        let negative = Double(negativeCount) / Double(max(totalWords, 1))
        let neutral = 1.0 - positive - negative
        
        return SentimentScore(positive: positive, negative: negative, neutral: max(neutral, 0.0))
    }
    
    // MARK: - Task Generation
    
    private func generateTasks(from content: ContentNodeData) async -> [SuggestedTask] {
        let text = content.contentText ?? ""
        var tasks: [SuggestedTask] = []
        
        // Task detection patterns
        let taskPatterns = [
            ("need to", TaskPriority.medium),
            ("should", TaskPriority.low),
            ("must", TaskPriority.high),
            ("urgent", TaskPriority.high),
            ("deadline", TaskPriority.high),
            ("todo", TaskPriority.medium),
            ("remember", TaskPriority.medium),
            ("action", TaskPriority.medium)
        ]
        
        let sentences = text.components(separatedBy: .init(charactersIn: ".!?\n"))
        
        for sentence in sentences {
            let lowerSentence = sentence.lowercased().trimmingCharacters(in: .whitespaces)
            
            for (pattern, priority) in taskPatterns {
                if lowerSentence.contains(pattern) {
                    let task = SuggestedTask(
                        title: extractTaskTitle(from: sentence),
                        description: sentence.trimmingCharacters(in: .whitespaces),
                        priority: priority,
                        dueDate: extractDueDate(from: sentence),
                        confidence: 0.7,
                        sourceContentId: content.id
                    )
                    tasks.append(task)
                    break
                }
            }
        }
        
        return Array(tasks.prefix(5)) // Limit to 5 tasks per content
    }
    
    // MARK: - Summary Generation
    
    private func generateSummary(_ text: String) async -> String {
        guard !text.isEmpty else { return "No content available" }
        
        if text.count <= 200 {
            return text
        }
        
        // Simple extractive summarization
        let sentences = text.components(separatedBy: .init(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if sentences.count <= 2 {
            return sentences.joined(separator: ". ")
        }
        
        // Take first and most important sentences
        let summary = sentences.prefix(2).joined(separator: ". ")
        return summary + (summary.hasSuffix(".") ? "" : ".")
    }
    
    // MARK: - Helper Functions
    
    private func updateProgress(_ progress: Double) async {
        await MainActor.run {
            self.analysisProgress = progress
        }
    }
    
    private func calculateConfidence(_ content: ContentNodeData, category: AIContentCategory) -> Double {
        var confidence = 0.5
        
        // Boost confidence based on content completeness
        if content.contentText?.isEmpty == false {
            confidence += 0.2
        }
        if content.ocrText?.isEmpty == false {
            confidence += 0.1
        }
        if content.type != .mixed {
            confidence += 0.1
        }
        
        return min(confidence, 1.0)
    }
    
    private func generateTags(keywords: [String], entities: [NamedEntity], category: AIContentCategory) -> [String] {
        var tags = Set<String>()
        
        // Add category as tag
        tags.insert(category.rawValue)
        
        // Add top keywords as tags
        tags.formUnion(Array(keywords.prefix(5)))
        
        // Add entity types as tags
        for entity in entities {
            tags.insert(entity.type.rawValue)
        }
        
        return Array(tags).sorted()
    }
    
    private func extractActionItems(_ text: String) -> [ActionItem] {
        let actionVerbs = ["call", "email", "send", "buy", "schedule", "book", "complete", "finish", "review"]
        let sentences = text.components(separatedBy: .init(charactersIn: ".!?\n"))
        
        var actionItems: [ActionItem] = []
        
        for sentence in sentences {
            let lowerSentence = sentence.lowercased()
            for verb in actionVerbs {
                if lowerSentence.contains(verb) {
                    actionItems.append(ActionItem(
                        action: verb,
                        description: sentence.trimmingCharacters(in: .whitespaces),
                        confidence: 0.6
                    ))
                    break
                }
            }
        }
        
        return Array(actionItems.prefix(3))
    }
    
    private func assessPriority(_ content: ContentNodeData, sentiment: SentimentScore) -> ContentPriority {
        let text = content.contentText ?? ""
        let urgentKeywords = ["urgent", "asap", "immediately", "critical", "emergency", "deadline"]
        
        if urgentKeywords.contains(where: { text.lowercased().contains($0) }) {
            return .high
        }
        
        if sentiment.negative > 0.3 {
            return .medium
        }
        
        return .low
    }
    
    private func extractTaskTitle(from sentence: String) -> String {
        let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.prefix(50))
    }
    
    private func extractDueDate(from sentence: String) -> Date? {
        let dateKeywords = ["tomorrow", "next week", "monday", "tuesday", "wednesday", "thursday", "friday"]
        let lowerSentence = sentence.lowercased()
        
        if lowerSentence.contains("tomorrow") {
            return Calendar.current.date(byAdding: .day, value: 1, to: Date())
        } else if lowerSentence.contains("next week") {
            return Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())
        }
        
        return nil
    }
    
    private func isStopWord(_ word: String) -> Bool {
        let stopWords = Set(["the", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by", "is", "are", "was", "were", "be", "been", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should", "may", "might", "must", "can", "this", "that", "these", "those", "a", "an"])
        return stopWords.contains(word.lowercased())
    }
}

// MARK: - Supporting Data Models

struct ContentAnalysis: Identifiable, Codable {
    let id = UUID()
    let contentId: UUID
    let language: String
    let category: AIContentCategory
    let keywords: [String]
    let entities: [NamedEntity]
    let sentiment: SentimentScore
    let confidence: Double
    let suggestedTags: [String]
    let suggestedTasks: [SuggestedTask]
    let summary: String
    let actionItems: [ActionItem]
    let priority: ContentPriority
    let analyzedAt: Date
}

enum AIAIContentCategory: String, CaseIterable, Codable {
    case business = "business"
    case personal = "personal"
    case learning = "learning"
    case reference = "reference"
    case task = "task"
    case entertainment = "entertainment"
}

struct NamedEntity: Identifiable, Codable, Hashable {
    let id = UUID()
    let text: String
    let type: AIEntityType
    let confidence: Double
    let range: Int
}

enum AIAIEntityType: String, CaseIterable, Codable {
    case person = "person"
    case location = "location"
    case organization = "organization"
    case date = "date"
    case other = "other"
}

struct SentimentScore: Codable {
    let positive: Double
    let negative: Double
    let neutral: Double
}

struct SuggestedTask: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let priority: TaskPriority
    let dueDate: Date?
    let confidence: Double
    let sourceContentId: UUID
}

enum TaskPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

struct ActionItem: Identifiable, Codable {
    let id = UUID()
    let action: String
    let description: String
    let confidence: Double
}

enum ContentPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}