//
//  SimpleAIProcessor.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import Foundation
import UIKit
@preconcurrency import Vision

// MARK: - Simple AI Processor
class SimpleAIProcessor: AIProcessorProtocol {
    
    static let shared = SimpleAIProcessor()
    
    private init() {}
    
    func processImage(_ imageData: Data) async throws -> AIProcessingResults {
        let startTime = Date()
        
        // Basic OCR using Vision framework
        let extractedText = try await extractTextFromImage(imageData)
        
        // Simple object detection simulation
        let detectedObjects = generateMockObjects()
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        return AIProcessingResults(
            extractedText: extractedText.isEmpty ? nil : extractedText,
            summary: generateSummary(from: extractedText),
            detectedObjects: detectedObjects,
            confidence: 0.85,
            processingTime: processingTime
        )
    }
    
    // MARK: - Private Methods
    private func extractTextFromImage(_ imageData: Data) async throws -> String {
        guard let image = UIImage(data: imageData)?.cgImage else {
            return ""
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: recognizedText)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func generateSummary(from text: String) -> String? {
        guard !text.isEmpty else { return nil }
        
        // Simple summary generation (first sentence or first 100 characters)
        let sentences = text.components(separatedBy: ". ")
        if let firstSentence = sentences.first, !firstSentence.isEmpty {
            return firstSentence + (firstSentence.hasSuffix(".") ? "" : ".")
        }
        
        return String(text.prefix(100)) + (text.count > 100 ? "..." : "")
    }
    
    private func generateMockObjects() -> [DetectedObject] {
        // Simple mock objects for demo purposes
        let possibleObjects = ["document", "text", "image", "photo", "screenshot"]
        let selectedObject = possibleObjects.randomElement() ?? "content"
        
        return [
            DetectedObject(
                label: selectedObject,
                confidence: Double.random(in: 0.7...0.95),
                boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
            )
        ]
    }
}