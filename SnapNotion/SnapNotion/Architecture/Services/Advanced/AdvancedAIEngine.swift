//
//  AdvancedAIEngine.swift
//  SnapNotion
//
//  Advanced AI processing engine with computer vision, NLP, and ML capabilities
//  Created by A. C. on 8/31/25.
//

import Foundation
import UIKit
import Vision
import VisionKit
import NaturalLanguage
import CoreML

// MARK: - Advanced AI Processing Engine
@MainActor
class AdvancedAIEngine: ObservableObject {
    
    static let shared = AdvancedAIEngine()
    
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    
    private let documentAnalyzer = DocumentAnalyzer()
    private let semanticAnalyzer = SemanticAnalyzer()
    private let taskIntelligence = TaskIntelligenceEngine()
    private let entityExtractor = EntityExtractor()
    
    private init() {}
    
    // MARK: - Main Advanced Processing Method
    func processContentAdvanced(_ imageData: Data, source: String) async throws -> AdvancedProcessingResults {
        isProcessing = true
        processingProgress = 0.0
        
        do {
            // Step 1: Document Analysis & OCR (20%)
            processingProgress = 0.1
            let documentResults = try await documentAnalyzer.analyzeDocument(imageData)
            processingProgress = 0.2
            
            // Step 2: Advanced OCR with table detection (40%)
            let ocrResults = try await performAdvancedOCR(imageData, documentType: documentResults.documentType)
            processingProgress = 0.4
            
            // Step 3: Semantic Analysis & Entity Extraction (60%)
            let semanticResults = try await semanticAnalyzer.analyzeContent(ocrResults.text, imageData: imageData)
            processingProgress = 0.6
            
            // Step 4: Intelligent Task Generation (80%)
            let intelligentTasks = try await taskIntelligence.generateIntelligentTasks(
                from: semanticResults,
                context: ocrResults,
                source: source
            )
            processingProgress = 0.8
            
            // Step 5: Knowledge Graph Integration (100%)
            let knowledgeConnections = try await extractKnowledgeConnections(from: semanticResults)
            processingProgress = 1.0
            
            let results = AdvancedProcessingResults(
                documentAnalysis: documentResults,
                ocrResults: ocrResults,
                semanticAnalysis: semanticResults,
                intelligentTasks: intelligentTasks,
                knowledgeConnections: knowledgeConnections,
                processingTime: Date().timeIntervalSince(Date()),
                confidence: calculateOverallConfidence(documentResults, ocrResults, semanticResults)
            )
            
            isProcessing = false
            return results
            
        } catch {
            isProcessing = false
            processingProgress = 0.0
            throw error
        }
    }
    
    // MARK: - Advanced OCR with Table Detection
    private func performAdvancedOCR(_ imageData: Data, documentType: DocumentType) async throws -> AdvancedOCRResults {
        guard let image = UIImage(data: imageData)?.cgImage else {
            throw AIProcessingError.invalidImageData
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let requests: [VNRequest] = createAdvancedVisionRequests(for: documentType) { results in
                continuation.resume(returning: results)
            } onError: { error in
                continuation.resume(throwing: error)
            }
            
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            
            do {
                try handler.perform(requests)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func createAdvancedVisionRequests(
        for documentType: DocumentType,
        onSuccess: @escaping (AdvancedOCRResults) -> Void,
        onError: @escaping (Error) -> Void
    ) -> [VNRequest] {
        
        var requests: [VNRequest] = []
        
        // 1. Advanced Text Recognition
        let textRequest = VNRecognizeTextRequest { request, error in
            if let error = error {
                onError(error)
                return
            }
            
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            
            // Extract text with positioning
            let textElements = observations.compactMap { observation -> TextElement? in
                guard let candidate = observation.topCandidates(1).first else { return nil }
                
                return TextElement(
                    text: candidate.string,
                    boundingBox: observation.boundingBox,
                    confidence: Double(candidate.confidence),
                    recognitionLevel: .word
                )
            }
            
            // Detect structured content
            let structuredContent = self.detectStructuredContent(from: textElements)
            
            let results = AdvancedOCRResults(
                text: textElements.map { $0.text }.joined(separator: "\n"),
                textElements: textElements,
                structuredContent: structuredContent,
                documentType: documentType,
                confidence: textElements.map { $0.confidence }.reduce(0.0, +) / Double(textElements.count)
            )
            
            onSuccess(results)
        }
        
        textRequest.recognitionLevel = VNRequestTextRecognitionLevel.accurate
        textRequest.usesLanguageCorrection = true
        textRequest.recognitionLanguages = ["en-US", "zh-CN", "zh-TW"]
        
        requests.append(textRequest)
        
        // 2. Document Structure Detection
        if documentType == .form || documentType == .table {
            let rectangleRequest = VNDetectRectanglesRequest { request, error in
                // Process detected rectangles for table structure
            }
            rectangleRequest.minimumAspectRatio = 0.1
            rectangleRequest.maximumObservations = 20
            requests.append(rectangleRequest)
        }
        
        return requests
    }
    
    // MARK: - Structured Content Detection
    private func detectStructuredContent(from textElements: [TextElement]) -> StructuredContent {
        let text = textElements.map { $0.text }.joined(separator: "\n")
        
        // Detect tables
        let tables = detectTables(in: textElements)
        
        // Detect lists
        let lists = detectLists(in: text)
        
        // Detect key-value pairs
        let keyValuePairs = detectKeyValuePairs(in: text)
        
        // Detect contact information
        let contactInfo = detectContactInformation(in: text)
        
        // Detect dates and times
        let dateTimeInfo = detectDateTimeInformation(in: text)
        
        return StructuredContent(
            tables: tables,
            lists: lists,
            keyValuePairs: keyValuePairs,
            contactInfo: contactInfo,
            dateTimeInfo: dateTimeInfo
        )
    }
    
    private func detectTables(in textElements: [TextElement]) -> [DetectedTable] {
        // Group text elements by rows based on y-coordinate
        let sortedElements = textElements.sorted { $0.boundingBox.minY > $1.boundingBox.minY }
        
        var tables: [DetectedTable] = []
        var currentRows: [[TextElement]] = []
        var lastY: CGFloat = -1
        let rowThreshold: CGFloat = 0.02 // 2% of image height
        
        for element in sortedElements {
            let elementY = element.boundingBox.minY
            
            if lastY == -1 || abs(elementY - lastY) < rowThreshold {
                // Same row
                if currentRows.isEmpty {
                    currentRows.append([element])
                } else {
                    currentRows[currentRows.count - 1].append(element)
                }
            } else {
                // New row
                currentRows.append([element])
            }
            
            lastY = elementY
        }
        
        // Analyze rows to detect table structure
        if currentRows.count >= 2 {
            let columnCount = currentRows.map { $0.count }.max() ?? 0
            
            if columnCount >= 2 {
                let tableData = currentRows.map { row -> [String] in
                    return row.sorted { $0.boundingBox.minX < $1.boundingBox.minX }
                              .map { $0.text }
                }
                
                tables.append(DetectedTable(
                    rows: tableData,
                    columnCount: columnCount,
                    confidence: 0.8
                ))
            }
        }
        
        return tables
    }
    
    private func detectLists(in text: String) -> [DetectedList] {
        var lists: [DetectedList] = []
        
        // Detect bullet points
        let bulletPatterns = [
            "^\\s*[•·-]\\s+(.+)$",
            "^\\s*\\d+\\.\\s+(.+)$",
            "^\\s*[a-zA-Z]\\.\\s+(.+)$",
            "^\\s*[ivxlcdm]+\\.\\s+(.+)$"
        ]
        
        for pattern in bulletPatterns {
            let regex = try! NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines, .caseInsensitive])
            let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
            
            if matches.count >= 2 {
                let items = matches.compactMap { match -> String? in
                    guard match.numberOfRanges > 1 else { return nil }
                    let range = match.range(at: 1)
                    return String(text[Range(range, in: text)!])
                }
                
                if !items.isEmpty {
                    lists.append(DetectedList(
                        items: items,
                        type: pattern.contains("\\d+") ? .numbered : .bulleted,
                        confidence: 0.9
                    ))
                }
            }
        }
        
        return lists
    }
    
    private func detectKeyValuePairs(in text: String) -> [KeyValuePair] {
        var pairs: [KeyValuePair] = []
        
        // Common key-value patterns
        let patterns = [
            "([A-Za-z\\s]+):\\s*(.+)",
            "([A-Za-z\\s]+)\\s*-\\s*(.+)",
            "([A-Za-z\\s]+)\\s*=\\s*(.+)"
        ]
        
        for pattern in patterns {
            let regex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
            
            for match in matches {
                if match.numberOfRanges == 3 {
                    let keyRange = match.range(at: 1)
                    let valueRange = match.range(at: 2)
                    
                    let key = String(text[Range(keyRange, in: text)!]).trimmingCharacters(in: .whitespaces)
                    let value = String(text[Range(valueRange, in: text)!]).trimmingCharacters(in: .whitespaces)
                    
                    pairs.append(KeyValuePair(
                        key: key,
                        value: value,
                        confidence: 0.85
                    ))
                }
            }
        }
        
        return pairs
    }
    
    private func detectContactInformation(in text: String) -> ContactInformation? {
        let emailRegex = try! NSRegularExpression(pattern: "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", options: [.caseInsensitive])
        let phoneRegex = try! NSRegularExpression(pattern: "(\\+?\\d{1,3}[-.\\s]?)?\\(?\\d{3}\\)?[-.\\s]?\\d{3}[-.\\s]?\\d{4}", options: [])
        
        let emailMatches = emailRegex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
        let phoneMatches = phoneRegex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
        
        var emails: [String] = []
        var phones: [String] = []
        
        for match in emailMatches {
            let email = String(text[Range(match.range, in: text)!])
            emails.append(email)
        }
        
        for match in phoneMatches {
            let phone = String(text[Range(match.range, in: text)!])
            phones.append(phone)
        }
        
        if !emails.isEmpty || !phones.isEmpty {
            return ContactInformation(
                emails: emails,
                phoneNumbers: phones,
                confidence: 0.9
            )
        }
        
        return nil
    }
    
    private func detectDateTimeInformation(in text: String) -> [DateTimeInfo] {
        var dateTimeInfos: [DateTimeInfo] = []
        
        // Date patterns
        let datePatterns = [
            "\\b\\d{1,2}/\\d{1,2}/\\d{2,4}\\b",
            "\\b\\d{1,2}-\\d{1,2}-\\d{2,4}\\b",
            "\\b\\d{4}-\\d{1,2}-\\d{1,2}\\b",
            "\\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\\.?\\s+\\d{1,2},?\\s+\\d{4}\\b"
        ]
        
        for pattern in datePatterns {
            let regex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
            
            for match in matches {
                let dateString = String(text[Range(match.range, in: text)!])
                
                dateTimeInfos.append(DateTimeInfo(
                    originalText: dateString,
                    type: .date,
                    confidence: 0.8
                ))
            }
        }
        
        return dateTimeInfos
    }
    
    // MARK: - Knowledge Graph Connections
    private func extractKnowledgeConnections(from semanticResults: SemanticAnalysisResults) -> [KnowledgeConnection] {
        var connections: [KnowledgeConnection] = []
        
        // Create connections between entities
        for entity in semanticResults.entities {
            for otherEntity in semanticResults.entities {
                if entity.id != otherEntity.id {
                    let relationship = determineRelationship(between: entity, and: otherEntity, in: semanticResults.fullText)
                    
                    if relationship.strength > 0.5 {
                        connections.append(KnowledgeConnection(
                            fromEntity: entity.id,
                            toEntity: otherEntity.id,
                            relationshipType: relationship.type,
                            strength: relationship.strength,
                            evidence: relationship.evidence
                        ))
                    }
                }
            }
        }
        
        return connections
    }
    
    private func determineRelationship(between entity1: DetectedEntity, and entity2: DetectedEntity, in text: String) -> EntityRelationship {
        // Simple proximity-based relationship detection
        let distance = abs(entity1.range.location - entity2.range.location)
        let maxDistance = text.count / 10
        
        let proximityScore = max(0.0, 1.0 - Double(distance) / Double(maxDistance))
        
        // Determine relationship type based on entity types
        let relationshipType: KnowledgeRelationshipType
        if entity1.type == .person && entity2.type == .organization {
            relationshipType = .worksFor
        } else if entity1.type == .location && entity2.type == .event {
            relationshipType = .locatedAt
        } else {
            relationshipType = .relatedTo
        }
        
        return EntityRelationship(
            type: relationshipType,
            strength: proximityScore,
            evidence: "Entities appear in close proximity"
        )
    }
    
    // MARK: - Confidence Calculation
    private func calculateOverallConfidence(
        _ documentResults: DocumentAnalysisResults,
        _ ocrResults: AdvancedOCRResults,
        _ semanticResults: SemanticAnalysisResults
    ) -> Double {
        let weights = [0.3, 0.4, 0.3] // Document, OCR, Semantic
        let confidences = [documentResults.confidence, ocrResults.confidence, semanticResults.confidence]
        
        return zip(weights, confidences).map(*).reduce(0, +)
    }
}

// MARK: - Supporting Classes
class DocumentAnalyzer {
    func analyzeDocument(_ imageData: Data) async throws -> DocumentAnalysisResults {
        // Simulate document type classification
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Simple heuristic-based classification
        let documentType = classifyDocumentType(imageData)
        
        return DocumentAnalysisResults(
            documentType: documentType,
            layout: analyzeDocumentLayout(imageData),
            quality: assessImageQuality(imageData),
            confidence: 0.85
        )
    }
    
    private func classifyDocumentType(_ imageData: Data) -> DocumentType {
        // Placeholder classification logic
        return .document
    }
    
    private func analyzeDocumentLayout(_ imageData: Data) -> DocumentLayout {
        return DocumentLayout(
            hasColumns: false,
            hasHeaders: true,
            hasFooters: false,
            textDensity: 0.7
        )
    }
    
    private func assessImageQuality(_ imageData: Data) -> ImageQuality {
        return ImageQuality(
            resolution: .high,
            clarity: 0.9,
            lighting: 0.8,
            orientation: .upright
        )
    }
}

class SemanticAnalyzer {
    private let languageRecognizer = NLLanguageRecognizer()
    
    func analyzeContent(_ text: String, imageData: Data) async throws -> SemanticAnalysisResults {
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Language detection
        languageRecognizer.processString(text)
        let dominantLanguage = languageRecognizer.dominantLanguage ?? .undetermined
        
        // Entity extraction
        let entities = extractEntities(from: text)
        
        // Sentiment analysis
        let sentiment = analyzeSentiment(text)
        
        // Topic extraction
        let topics = extractTopics(from: text)
        
        // Key phrases
        let keyPhrases = extractKeyPhrases(from: text)
        
        return SemanticAnalysisResults(
            fullText: text,
            language: dominantLanguage,
            entities: entities,
            sentiment: sentiment,
            topics: topics,
            keyPhrases: keyPhrases,
            confidence: 0.88
        )
    }
    
    private func extractEntities(from text: String) -> [DetectedEntity] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        var entities: [DetectedEntity] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, range in
            if let tag = tag {
                let entityText = String(text[range])
                let entityType = convertNLTagToEntityType(tag)
                
                entities.append(DetectedEntity(
                    id: UUID(),
                    text: entityText,
                    type: entityType,
                    range: NSRange(range, in: text),
                    confidence: 0.8
                ))
            }
            return true
        }
        
        return entities
    }
    
    private func convertNLTagToEntityType(_ tag: NLTag) -> EntityType {
        switch tag {
        case .personalName:
            return .person
        case .placeName:
            return .location
        case .organizationName:
            return .organization
        default:
            return .other
        }
    }
    
    private func analyzeSentiment(_ text: String) -> SentimentAnalysis {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        
        var totalScore: Double = 0
        var count = 0
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .sentence, scheme: .sentimentScore) { tag, range in
            if let tag = tag, let score = Double(tag.rawValue) {
                totalScore += score
                count += 1
            }
            return true
        }
        
        let averageScore = count > 0 ? totalScore / Double(count) : 0
        
        let sentiment: SentimentType
        if averageScore > 0.1 {
            sentiment = .positive
        } else if averageScore < -0.1 {
            sentiment = .negative
        } else {
            sentiment = .neutral
        }
        
        return SentimentAnalysis(
            type: sentiment,
            score: averageScore,
            confidence: 0.7
        )
    }
    
    private func extractTopics(from text: String) -> [Topic] {
        // Simple keyword-based topic extraction
        let commonTopics = [
            "meeting", "project", "deadline", "task", "business", "finance",
            "technology", "research", "education", "health", "travel"
        ]
        
        var detectedTopics: [Topic] = []
        let lowercaseText = text.lowercased()
        
        for topic in commonTopics {
            if lowercaseText.contains(topic) {
                detectedTopics.append(Topic(
                    name: topic,
                    relevance: 0.8,
                    confidence: 0.7
                ))
            }
        }
        
        return detectedTopics
    }
    
    private func extractKeyPhrases(from text: String) -> [KeyPhrase] {
        // Extract noun phrases
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var keyPhrases: [KeyPhrase] = []
        var currentPhrase: [String] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            let word = String(text[range])
            
            if tag == .noun || tag == .adjective {
                currentPhrase.append(word)
            } else {
                if currentPhrase.count >= 2 {
                    keyPhrases.append(KeyPhrase(
                        text: currentPhrase.joined(separator: " "),
                        importance: Double(currentPhrase.count) * 0.3,
                        confidence: 0.7
                    ))
                }
                currentPhrase.removeAll()
            }
            
            return true
        }
        
        return keyPhrases
    }
}

class TaskIntelligenceEngine {
    func generateIntelligentTasks(
        from semanticResults: SemanticAnalysisResults,
        context: AdvancedOCRResults,
        source: String
    ) async throws -> [IntelligentTask] {
        try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
        
        var tasks: [IntelligentTask] = []
        
        // Task generation based on content type and entities
        tasks.append(contentsOf: generateTasksFromEntities(semanticResults.entities))
        tasks.append(contentsOf: generateTasksFromKeyPhrases(semanticResults.keyPhrases))
        tasks.append(contentsOf: generateTasksFromStructuredContent(context.structuredContent))
        
        // Add source-based tasks
        if let sourceTask = generateSourceBasedTask(source: source, content: semanticResults.fullText) {
            tasks.append(sourceTask)
        }
        
        return tasks
    }
    
    private func generateTasksFromEntities(_ entities: [DetectedEntity]) -> [IntelligentTask] {
        var tasks: [IntelligentTask] = []
        
        for entity in entities {
            switch entity.type {
            case .person:
                tasks.append(IntelligentTask(
                    id: UUID(),
                    title: "Follow up with \(entity.text)",
                    description: "Reach out to \(entity.text) based on the captured information",
                    predictedPriority: .medium,
                    confidenceScore: entity.confidence,
                    suggestedDueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
                    dependencies: [],
                    contextualReasons: ["Person mentioned in captured content"],
                    category: .communication
                ))
                
            case .organization:
                tasks.append(IntelligentTask(
                    id: UUID(),
                    title: "Research \(entity.text)",
                    description: "Gather more information about \(entity.text)",
                    predictedPriority: .low,
                    confidenceScore: entity.confidence * 0.8,
                    suggestedDueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                    dependencies: [],
                    contextualReasons: ["Organization mentioned in captured content"],
                    category: .research
                ))
                
            case .location:
                tasks.append(IntelligentTask(
                    id: UUID(),
                    title: "Check details for \(entity.text)",
                    description: "Verify information related to \(entity.text)",
                    predictedPriority: .low,
                    confidenceScore: entity.confidence * 0.7,
                    suggestedDueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
                    dependencies: [],
                    contextualReasons: ["Location mentioned in captured content"],
                    category: .planning
                ))
                
            default:
                break
            }
        }
        
        return tasks
    }
    
    private func generateTasksFromKeyPhrases(_ keyPhrases: [KeyPhrase]) -> [IntelligentTask] {
        let actionKeywords = [
            "deadline": ("Check deadline", IntelligentTask.TaskPriority.high, 1),
            "meeting": ("Prepare for meeting", IntelligentTask.TaskPriority.medium, 2),
            "project": ("Review project status", IntelligentTask.TaskPriority.medium, 3),
            "review": ("Complete review", IntelligentTask.TaskPriority.medium, 2),
            "submit": ("Prepare submission", IntelligentTask.TaskPriority.high, 1),
            "follow up": ("Follow up on item", IntelligentTask.TaskPriority.medium, 3)
        ]
        
        var tasks: [IntelligentTask] = []
        
        for phrase in keyPhrases {
            for (keyword, taskInfo) in actionKeywords {
                if phrase.text.lowercased().contains(keyword) {
                    tasks.append(IntelligentTask(
                        id: UUID(),
                        title: taskInfo.0,
                        description: "Action item derived from: \(phrase.text)",
                        predictedPriority: taskInfo.1,
                        confidenceScore: phrase.confidence,
                        suggestedDueDate: Calendar.current.date(byAdding: .day, value: taskInfo.2, to: Date()),
                        dependencies: [],
                        contextualReasons: ["Key phrase '\(phrase.text)' suggests actionable item"],
                        category: .task
                    ))
                }
            }
        }
        
        return tasks
    }
    
    private func generateTasksFromStructuredContent(_ structuredContent: StructuredContent) -> [IntelligentTask] {
        var tasks: [IntelligentTask] = []
        
        // Generate tasks from detected lists
        for list in structuredContent.lists {
            tasks.append(IntelligentTask(
                id: UUID(),
                title: "Process checklist items",
                description: "Review and complete items from detected list",
                predictedPriority: .medium,
                confidenceScore: list.confidence,
                suggestedDueDate: Calendar.current.date(byAdding: .day, value: 4, to: Date()),
                dependencies: [],
                contextualReasons: ["Checklist detected with \(list.items.count) items"],
                category: .task
            ))
        }
        
        // Generate tasks from contact information
        if let contactInfo = structuredContent.contactInfo {
            if !contactInfo.emails.isEmpty || !contactInfo.phoneNumbers.isEmpty {
                tasks.append(IntelligentTask(
                    id: UUID(),
                    title: "Save contact information",
                    description: "Add detected contact details to address book",
                    predictedPriority: .low,
                    confidenceScore: contactInfo.confidence,
                    suggestedDueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
                    dependencies: [],
                    contextualReasons: ["Contact information detected in content"],
                    category: .organization
                ))
            }
        }
        
        return tasks
    }
    
    private func generateSourceBasedTask(source: String, content: String) -> IntelligentTask? {
        let title = "Review content from \(source)"
        let description = "Process and organize the captured content: \(String(content.prefix(100)))"
        
        return IntelligentTask(
            id: UUID(),
            title: title,
            description: description,
            predictedPriority: .low,
            confidenceScore: 0.7,
            suggestedDueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
            dependencies: [],
            contextualReasons: ["Content captured from \(source)"],
            category: .organization
        )
    }
}

class EntityExtractor {
    func extractEntities(from text: String) async throws -> [DetectedEntity] {
        // This would integrate with more advanced NLP models
        // For now, using the same logic as SemanticAnalyzer
        let analyzer = SemanticAnalyzer()
        let results = try await analyzer.analyzeContent(text, imageData: Data())
        return results.entities
    }
}

// MARK: - AI Processing Error
enum AIProcessingError: LocalizedError {
    case invalidImageData
    case modelLoadingFailed
    case processingTimeout
    case insufficientConfidence
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Invalid image data provided"
        case .modelLoadingFailed:
            return "Failed to load AI models"
        case .processingTimeout:
            return "AI processing timed out"
        case .insufficientConfidence:
            return "AI processing confidence too low"
        }
    }
}