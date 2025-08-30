//
//  ContentEntity+Extensions.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import Foundation
import CoreData

// MARK: - ContentEntity Extensions
extension ContentEntity {
    
    // MARK: - Conversion Methods
    func toContentItem() -> ContentItem? {
        guard let id = self.id,
              let title = self.title,
              let preview = self.preview,
              let source = self.source,
              let sourceAppString = self.sourceApp,
              let typeString = self.type,
              let timestamp = self.timestamp,
              let processingStatusString = self.processingStatus else {
            return nil
        }
        
        let sourceApp = AppSource(rawValue: sourceAppString) ?? .unknown
        let type = ContentType(rawValue: typeString) ?? .text
        let processingStatus = ProcessingStatus(rawValue: processingStatusString) ?? .pending
        
        // Convert attachments
        let attachmentItems = (attachments?.allObjects as? [AttachmentEntity])?.compactMap { $0.toAttachmentPreview() } ?? []
        
        // Parse metadata
        let metadata = parseMetadata()
        
        return ContentItem(
            title: title,
            preview: preview,
            source: source,
            sourceApp: sourceApp,
            timestamp: timestamp,
            type: type,
            isFavorite: isFavorite,
            attachments: attachmentItems,
            metadata: metadata,
            processingStatus: processingStatus
        )
    }
    
    func populate(from item: ContentItem) {
        self.id = item.id
        self.title = item.title
        self.preview = item.preview
        self.source = item.source
        self.sourceApp = item.sourceApp.rawValue
        self.timestamp = item.timestamp
        self.type = item.type.rawValue
        self.isFavorite = item.isFavorite
        self.processingStatus = item.processingStatus.rawValue
        
        // Serialize metadata to JSON
        if let metadataData = try? JSONEncoder().encode(item.metadata),
           let metadataString = String(data: metadataData, encoding: .utf8) {
            self.metadataJSON = metadataString
        }
        
        // Handle attachments
        syncAttachments(with: item.attachments)
        
        // Handle AI results
        if let aiResults = item.metadata.aiProcessingResults {
            syncAIResults(with: aiResults)
        }
    }
    
    // MARK: - Private Helper Methods
    private func parseMetadata() -> ContentMetadata {
        guard let metadataJSON = self.metadataJSON,
              let data = metadataJSON.data(using: .utf8),
              let metadata = try? JSONDecoder().decode(ContentMetadata.self, from: data) else {
            return ContentMetadata()
        }
        return metadata
    }
    
    private func syncAttachments(with newAttachments: [AttachmentPreview]) {
        guard let context = managedObjectContext else { return }
        
        // Remove existing attachments that are not in the new list
        if let existingAttachments = attachments?.allObjects as? [AttachmentEntity] {
            for existing in existingAttachments {
                if !newAttachments.contains(where: { $0.id == existing.id }) {
                    context.delete(existing)
                }
            }
        }
        
        // Add or update attachments
        for attachment in newAttachments {
            let existingAttachment = (attachments?.allObjects as? [AttachmentEntity])?.first { $0.id == attachment.id }
            
            if let existing = existingAttachment {
                existing.populate(from: attachment)
            } else {
                let newEntity = AttachmentEntity(context: context)
                newEntity.populate(from: attachment)
                addToAttachments(newEntity)
            }
        }
    }
    
    private func syncAIResults(with results: AIProcessingResults) {
        guard let context = managedObjectContext else { return }
        
        if let existingResults = aiResults {
            existingResults.populate(from: results)
        } else {
            let newResults = AIResultsEntity(context: context)
            newResults.populate(from: results)
            self.aiResults = newResults
        }
    }
}

// MARK: - AttachmentEntity Extensions
extension AttachmentEntity {
    
    func toAttachmentPreview() -> AttachmentPreview? {
        guard let id = self.id,
              let name = self.name,
              let type = self.type,
              let fullPath = self.fullPath else {
            return nil
        }
        
        return AttachmentPreview(
            name: name,
            type: type,
            size: size,
            thumbnailPath: thumbnailPath,
            fullPath: fullPath
        )
    }
    
    func populate(from attachment: AttachmentPreview) {
        self.id = attachment.id
        self.name = attachment.name
        self.type = attachment.type
        self.size = attachment.size
        self.thumbnailPath = attachment.thumbnailPath
        self.fullPath = attachment.fullPath
    }
}

// MARK: - AIResultsEntity Extensions
extension AIResultsEntity {
    
    func toAIProcessingResults() -> AIProcessingResults? {
        let detectedObjects: [AIProcessingResults.DetectedObject] = {
            guard let json = detectedObjectsJSON,
                  let data = json.data(using: .utf8),
                  let objects = try? JSONDecoder().decode([AIProcessingResults.DetectedObject].self, from: data) else {
                return []
            }
            return objects
        }()
        
        let entities: [AIProcessingResults.NamedEntity] = {
            guard let json = entitiesJSON,
                  let data = json.data(using: .utf8),
                  let entities = try? JSONDecoder().decode([AIProcessingResults.NamedEntity].self, from: data) else {
                return []
            }
            return entities
        }()
        
        let categoriesArray: [String] = {
            guard let categoriesString = categories else { return [] }
            return categoriesString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }()
        
        return AIProcessingResults(
            extractedText: extractedText,
            detectedObjects: detectedObjects,
            extractedEntities: entities,
            summary: summary,
            categories: categoriesArray,
            confidence: confidence,
            processingTime: processingTime
        )
    }
    
    func populate(from results: AIProcessingResults) {
        self.id = UUID()
        self.extractedText = results.extractedText
        self.summary = results.summary
        self.categories = results.categories.joined(separator: ", ")
        self.confidence = results.confidence
        self.processingTime = results.processingTime
        
        // Serialize detected objects to JSON
        if let objectsData = try? JSONEncoder().encode(results.detectedObjects),
           let objectsString = String(data: objectsData, encoding: .utf8) {
            self.detectedObjectsJSON = objectsString
        }
        
        // Serialize entities to JSON
        if let entitiesData = try? JSONEncoder().encode(results.extractedEntities),
           let entitiesString = String(data: entitiesData, encoding: .utf8) {
            self.entitiesJSON = entitiesString
        }
    }
}

// MARK: - ImageMetadataEntity Extensions
extension ImageMetadataEntity {
    
    func toImageMetadata() -> ImageMetadata? {
        let dimensions = CGSize(width: width, height: height)
        let location = (latitude != 0 && longitude != 0) ? 
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude) : nil
        
        return ImageMetadata(
            dimensions: dimensions,
            colorSpace: colorSpace ?? "sRGB",
            hasAlpha: hasAlpha,
            dpi: dpi,
            cameraMake: cameraMake,
            cameraModel: cameraModel,
            location: location,
            captureDate: captureDate
        )
    }
    
    func populate(from metadata: ImageMetadata) {
        self.id = UUID()
        self.width = metadata.dimensions.width
        self.height = metadata.dimensions.height
        self.colorSpace = metadata.colorSpace
        self.hasAlpha = metadata.hasAlpha
        self.dpi = metadata.dpi
        self.cameraMake = metadata.cameraMake
        self.cameraModel = metadata.cameraModel
        self.captureDate = metadata.captureDate
        
        if let location = metadata.location {
            self.latitude = location.latitude
            self.longitude = location.longitude
        }
    }
}

// MARK: - Core Location Import
import CoreLocation