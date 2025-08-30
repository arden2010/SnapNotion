//
//  AIProcessor.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import Foundation
import Vision
import NaturalLanguage
import CoreML
import UIKit

// MARK: - AI Processor Protocol
protocol AIProcessorProtocol {
    func processText(_ text: String) async throws -> AIProcessingResults
    func processImage(_ imageData: Data) async throws -> AIProcessingResults
    func processWebContent(_ url: URL) async throws -> WebProcessingResults
    func extractEntities(from text: String) async throws -> [AIProcessingResults.NamedEntity]
    func analyzeSentiment(in text: String) async throws -> TextMetadata.TextSentiment
}

// MARK: - AI Processor Implementation
@MainActor
class AIProcessor: AIProcessorProtocol {
    
    static let shared = AIProcessor()
    
    // MARK: - Private Properties
    private let textAnalyzer = TextAnalyzer()
    private let imageAnalyzer = ImageAnalyzer()
    private let webContentExtractor = WebContentExtractor()
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    func processText(_ text: String) async throws -> AIProcessingResults {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        async let entities = extractEntities(from: text)
        async let sentiment = analyzeSentiment(in: text)
        async let summary = generateSummary(from: text)
        async let categories = categorizeText(text)
        
        let extractedEntities = try await entities
        let textSentiment = try await sentiment
        let textSummary = try await summary
        let textCategories = try await categories
        
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        
        return AIProcessingResults(
            extractedText: text,
            detectedObjects: [],
            extractedEntities: extractedEntities,
            summary: textSummary,
            categories: textCategories,
            confidence: calculateConfidence(for: extractedEntities),
            processingTime: processingTime
        )
    }
    
    func processImage(_ imageData: Data) async throws -> AIProcessingResults {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard let image = UIImage(data: imageData) else {
            throw AIProcessorError.invalidImageData
        }
        
        async let objects = detectObjects(in: image)
        async let text = extractTextFromImage(image)
        
        let detectedObjects = try await objects
        let extractedText = try await text
        
        var entities: [AIProcessingResults.NamedEntity] = []
        var summary: String?
        var categories: [String] = []
        
        if !extractedText.isEmpty {
            entities = try await extractEntities(from: extractedText)
            summary = try await generateSummary(from: extractedText)
            categories = try await categorizeText(extractedText)
        }
        
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        
        return AIProcessingResults(
            extractedText: extractedText.isEmpty ? nil : extractedText,
            detectedObjects: detectedObjects,
            extractedEntities: entities,
            summary: summary,
            categories: categories,
            confidence: calculateConfidence(for: detectedObjects, entities: entities),
            processingTime: processingTime
        )
    }
    
    func processWebContent(_ url: URL) async throws -> WebProcessingResults {
        let webContent = try await webContentExtractor.extractContent(from: url)
        
        let fullText = [webContent.title, webContent.description, webContent.bodyText]
            .compactMap { $0 }
            .joined(separator: "\n\n")
        
        let aiResults: AIProcessingResults?
        if !fullText.isEmpty {
            aiResults = try await processText(fullText)
        } else {
            aiResults = nil
        }
        
        return WebProcessingResults(
            url: url,
            webMetadata: webContent,
            aiResults: aiResults
        )
    }
    
    func extractEntities(from text: String) async throws -> [AIProcessingResults.NamedEntity] {
        return await textAnalyzer.extractEntities(from: text)
    }
    
    func analyzeSentiment(in text: String) async throws -> TextMetadata.TextSentiment {
        return await textAnalyzer.analyzeSentiment(in: text)
    }
    
    // MARK: - Private Methods
    private func detectObjects(in image: UIImage) async throws -> [AIProcessingResults.DetectedObject] {
        return await imageAnalyzer.detectObjects(in: image)
    }
    
    private func extractTextFromImage(_ image: UIImage) async throws -> String {
        return await imageAnalyzer.extractText(from: image)
    }
    
    private func generateSummary(from text: String) async throws -> String? {
        return await textAnalyzer.generateSummary(from: text)
    }
    
    private func categorizeText(_ text: String) async throws -> [String] {
        return await textAnalyzer.categorize(text)
    }
    
    private func calculateConfidence(for objects: [AIProcessingResults.DetectedObject], entities: [AIProcessingResults.NamedEntity] = []) -> Double {
        let objectConfidences = objects.map { $0.confidence }
        let entityConfidences = entities.map { $0.confidence }
        let allConfidences = objectConfidences + entityConfidences
        
        guard !allConfidences.isEmpty else { return 0.0 }
        
        return allConfidences.reduce(0, +) / Double(allConfidences.count)
    }
    
    private func calculateConfidence(for entities: [AIProcessingResults.NamedEntity]) -> Double {
        guard !entities.isEmpty else { return 0.0 }
        
        let confidenceSum = entities.map { $0.confidence }.reduce(0, +)
        return confidenceSum / Double(entities.count)
    }
}

// MARK: - Text Analyzer
class TextAnalyzer {
    
    func extractEntities(from text: String) async -> [AIProcessingResults.NamedEntity] {
        let recognizer = NLRecognizer(tagScheme: .nameType)
        recognizer.string = text
        
        var entities: [AIProcessingResults.NamedEntity] = []
        
        recognizer.enumerateTags(in: text.startIndex..<text.endIndex) { tag, range in
            guard let tag = tag else { return true }
            
            let entityText = String(text[range])
            let entityType: AIProcessingResults.NamedEntity.EntityType
            
            switch tag {
            case .personalName:
                entityType = .person
            case .organizationName:
                entityType = .organization
            case .placeName:
                entityType = .location
            default:
                return true
            }
            
            entities.append(AIProcessingResults.NamedEntity(
                text: entityText,
                type: entityType,
                confidence: 0.8 // NLRecognizer doesn't provide confidence, so we use a default
            ))
            
            return true
        }
        
        // Extract additional entities using pattern matching
        entities.append(contentsOf: extractPatternEntities(from: text))
        
        return entities
    }
    
    func analyzeSentiment(in text: String) async -> TextMetadata.TextSentiment {
        let sentimentPredictor = NLModel.sentimentPredictor
        let prediction = sentimentPredictor?.predictedLabel(for: text)
        
        switch prediction {
        case "Positive":
            return .positive
        case "Negative":
            return .negative
        default:
            return .neutral
        }
    }
    
    func generateSummary(from text: String) async -> String? {
        // Simple extractive summarization - take first few sentences
        let sentences = text.components(separatedBy: .punctuationCharacters)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 20 }
        
        if sentences.count > 3 {
            return sentences.prefix(3).joined(separator: ". ") + "."
        } else if !sentences.isEmpty {
            return sentences.joined(separator: ". ") + "."
        }
        
        return nil
    }
    
    func categorize(_ text: String) async -> [String] {
        var categories: [String] = []
        
        let lowercasedText = text.lowercased()
        
        // Simple keyword-based categorization
        let categoryKeywords: [String: [String]] = [
            "Technology": ["ai", "machine learning", "software", "code", "programming", "tech", "algorithm"],
            "Business": ["revenue", "profit", "market", "sales", "customer", "business", "strategy"],
            "Health": ["health", "medical", "doctor", "treatment", "disease", "medicine"],
            "Education": ["learn", "study", "education", "school", "university", "course"],
            "Travel": ["travel", "trip", "vacation", "flight", "hotel", "destination"],
            "Food": ["recipe", "food", "cooking", "restaurant", "meal", "ingredient"]
        ]
        
        for (category, keywords) in categoryKeywords {
            if keywords.contains(where: { lowercasedText.contains($0) }) {
                categories.append(category)
            }
        }
        
        return categories.isEmpty ? ["General"] : categories
    }
    
    private func extractPatternEntities(from text: String) -> [AIProcessingResults.NamedEntity] {
        var entities: [AIProcessingResults.NamedEntity] = []
        
        // Email pattern
        let emailRegex = try? NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}")
        if let regex = emailRegex {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    entities.append(AIProcessingResults.NamedEntity(
                        text: String(text[range]),
                        type: .email,
                        confidence: 0.9
                    ))
                }
            }
        }
        
        // URL pattern
        let urlRegex = try? NSRegularExpression(pattern: "https?://[^\\s]+")
        if let regex = urlRegex {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    entities.append(AIProcessingResults.NamedEntity(
                        text: String(text[range]),
                        type: .url,
                        confidence: 0.95
                    ))
                }
            }
        }
        
        // Phone pattern
        let phoneRegex = try? NSRegularExpression(pattern: "\\b\\d{3}-?\\d{3}-?\\d{4}\\b")
        if let regex = phoneRegex {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    entities.append(AIProcessingResults.NamedEntity(
                        text: String(text[range]),
                        type: .phone,
                        confidence: 0.8
                    ))
                }
            }
        }
        
        return entities
    }
}

// MARK: - Image Analyzer
class ImageAnalyzer {
    
    func detectObjects(in image: UIImage) async -> [AIProcessingResults.DetectedObject] {
        return await withCheckedContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: [])
                return
            }
            
            let request = VNRecognizeObjectsRequest { request, error in
                guard let observations = request.results as? [VNRecognizedObjectObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let objects = observations.map { observation in
                    AIProcessingResults.DetectedObject(
                        label: observation.labels.first?.identifier ?? "Unknown",
                        confidence: Double(observation.confidence),
                        boundingBox: observation.boundingBox
                    )
                }
                
                continuation.resume(returning: objects)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
    
    func extractText(from image: UIImage) async -> String {
        return await withCheckedContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: "")
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    try? observation.topCandidates(1).first?.string
                }
                
                continuation.resume(returning: recognizedStrings.joined(separator: "\n"))
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
}

// MARK: - Web Content Extractor
class WebContentExtractor {
    
    func extractContent(from url: URL) async throws -> WebMetadata {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let html = String(data: data, encoding: .utf8) else {
            throw AIProcessorError.webContentExtractionFailed
        }
        
        return parseHTML(html, baseURL: url)
    }
    
    private func parseHTML(_ html: String, baseURL: URL) -> WebMetadata {
        // Simple HTML parsing - in a real app, you'd use a proper HTML parser
        let title = extractMetaTag("title", from: html) ?? extractBetween("<title>", "</title>", in: html)
        let description = extractMetaTag("description", from: html)
        let siteName = extractMetaTag("site_name", from: html) ?? baseURL.host
        let author = extractMetaTag("author", from: html)
        
        // Extract publish date
        let publishedDate = extractMetaTag("published_time", from: html).flatMap { dateString in
            ISO8601DateFormatter().date(from: dateString)
        }
        
        // Extract image URL
        let imageURL = extractMetaTag("image", from: html).flatMap { URL(string: $0) }
        
        // Extract favicon
        let faviconURL = extractFavicon(from: html, baseURL: baseURL)
        
        return WebMetadata(
            title: title,
            description: description,
            siteName: siteName,
            faviconURL: faviconURL,
            imageURL: imageURL,
            publishedDate: publishedDate,
            author: author,
            tags: []
        )
    }
    
    private func extractMetaTag(_ name: String, from html: String) -> String? {
        let patterns = [
            "name=\"\(name)\" content=\"([^\"]*)",
            "property=\"og:\(name)\" content=\"([^\"]*)",
            "property=\"article:\(name)\" content=\"([^\"]*)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
                if let match = matches.first, match.numberOfRanges > 1,
                   let range = Range(match.range(at: 1), in: html) {
                    return String(html[range])
                }
            }
        }
        
        return nil
    }
    
    private func extractBetween(_ start: String, _ end: String, in html: String) -> String? {
        guard let startRange = html.range(of: start),
              let endRange = html.range(of: end, range: startRange.upperBound..<html.endIndex) else {
            return nil
        }
        
        let content = String(html[startRange.upperBound..<endRange.lowerBound])
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractFavicon(from html: String, baseURL: URL) -> URL? {
        let pattern = "rel=\"icon\" href=\"([^\"]*)\""
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
            if let match = matches.first, match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: html) {
                let iconPath = String(html[range])
                return URL(string: iconPath, relativeTo: baseURL)
            }
        }
        
        // Fallback to default favicon location
        return URL(string: "/favicon.ico", relativeTo: baseURL)
    }
}

// MARK: - AI Processor Error
enum AIProcessorError: LocalizedError {
    case invalidImageData
    case webContentExtractionFailed
    case processingTimeout
    case insufficientData
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Invalid image data provided"
        case .webContentExtractionFailed:
            return "Failed to extract web content"
        case .processingTimeout:
            return "Processing timeout exceeded"
        case .insufficientData:
            return "Insufficient data for processing"
        }
    }
}