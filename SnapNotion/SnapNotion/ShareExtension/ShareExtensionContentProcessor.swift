//
//  ShareExtensionContentProcessor.swift
//  SnapNotionShareExtension
//
//  Created by A. C. on 8/30/25.
//

import Foundation
import UIKit

// MARK: - Share Extension Errors
enum ShareExtensionError: LocalizedError {
    case appGroupContainerNotAccessible
    case fileWriteFailed(String)
    case contentProcessingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .appGroupContainerNotAccessible:
            return "Unable to access App Group container. Please check app configuration."
        case .fileWriteFailed(let path):
            return "Failed to write file at path: \(path)"
        case .contentProcessingFailed(let reason):
            return "Content processing failed: \(reason)"
        }
    }
}

// MARK: - Share Extension Content Processor
class ShareExtensionContentProcessor {
    
    // MARK: - Properties
    private let appGroupIdentifier = "group.com.snapnotion.app"
    private let containerURL: URL
    
    // MARK: - Initialization
    init() throws {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            throw ShareExtensionError.appGroupContainerNotAccessible
        }
        self.containerURL = url
        setupDirectories()
    }
    
    // MARK: - Public Methods
    func processSharedContent(_ content: SharedContent, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                // Save content data to shared container
                let savedContent = try await saveContentToContainer(content)
                
                // Create notification for main app
                try await notifyMainApp(of: savedContent)
                
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Private Methods
    private func setupDirectories() {
        let directories = ["images", "documents", "temp"]
        
        for directory in directories {
            let directoryURL = containerURL.appendingPathComponent(directory)
            try? FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
    
    private func saveContentToContainer(_ content: SharedContent) async throws -> SavedContentInfo {
        let contentId = UUID()
        let timestamp = Date()
        
        // Save binary data if present
        var savedDataPath: String?
        if let data = content.data {
            savedDataPath = try saveDataFile(data, contentId: contentId, type: content.type)
        }
        
        // Create content info
        let contentInfo = SavedContentInfo(
            id: contentId,
            type: content.type,
            text: content.text,
            url: content.url,
            sourceApp: content.sourceApp,
            dataPath: savedDataPath,
            metadata: content.metadata,
            timestamp: timestamp
        )
        
        // Save content info to shared queue
        try saveToSharedQueue(contentInfo)
        
        return contentInfo
    }
    
    private func saveDataFile(_ data: Data, contentId: UUID, type: ContentType) throws -> String {
        let fileExtension = getFileExtension(for: type)
        let fileName = "\(contentId.uuidString).\(fileExtension)"
        
        let subdirectory: String
        switch type {
        case .image:
            subdirectory = "images"
        case .pdf:
            subdirectory = "documents"
        default:
            subdirectory = "temp"
        }
        
        let fileURL = containerURL
            .appendingPathComponent(subdirectory)
            .appendingPathComponent(fileName)
        
        try data.write(to: fileURL)
        
        return fileURL.path
    }
    
    private func saveToSharedQueue(_ contentInfo: SavedContentInfo) throws {
        let queueURL = containerURL.appendingPathComponent("shared_queue.json")
        
        // Load existing queue
        var queue: [SavedContentInfo] = []
        if let data = try? Data(contentsOf: queueURL) {
            queue = (try? JSONDecoder().decode([SavedContentInfo].self, from: data)) ?? []
        }
        
        // Add new content
        queue.append(contentInfo)
        
        // Keep only the last 100 items to prevent unbounded growth
        if queue.count > 100 {
            queue = Array(queue.suffix(100))
        }
        
        // Save updated queue
        let data = try JSONEncoder().encode(queue)
        try data.write(to: queueURL)
    }
    
    private func notifyMainApp(of content: SavedContentInfo) async throws {
        // Create a notification using URL scheme or user defaults
        let notificationData: [String: Any] = [
            "type": "new_shared_content",
            "contentId": content.id.uuidString,
            "timestamp": content.timestamp.timeIntervalSince1970
        ]
        
        // Save notification to shared user defaults
        let userDefaults = UserDefaults(suiteName: appGroupIdentifier)
        userDefaults?.set(notificationData, forKey: "latest_shared_content")
        userDefaults?.synchronize()
        
        // Send local notification if the main app supports it
        await sendLocalNotification(for: content)
    }
    
    private func sendLocalNotification(for content: SavedContentInfo) async {
        let center = UNUserNotificationCenter.current()
        
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "New Content Saved"
        notificationContent.body = "Content from \(content.sourceApp.displayName) has been processed"
        notificationContent.sound = .default
        notificationContent.userInfo = [
            "contentId": content.id.uuidString,
            "sourceApp": content.sourceApp.rawValue
        ]
        
        let request = UNNotificationRequest(
            identifier: "shared_content_\(content.id.uuidString)",
            content: notificationContent,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        try? await center.add(request)
    }
    
    private func getFileExtension(for type: ContentType) -> String {
        switch type {
        case .image:
            return "jpg"
        case .pdf:
            return "pdf"
        case .text:
            return "txt"
        default:
            return "data"
        }
    }
}

// MARK: - Saved Content Info
struct SavedContentInfo: Codable {
    let id: UUID
    let type: ContentType
    let text: String?
    let url: URL?
    let sourceApp: AppSource
    let dataPath: String?
    let metadata: [String: String] // Simplified for JSON serialization
    let timestamp: Date
    
    init(
        id: UUID,
        type: ContentType,
        text: String?,
        url: URL?,
        sourceApp: AppSource,
        dataPath: String?,
        metadata: [String: Any],
        timestamp: Date
    ) {
        self.id = id
        self.type = type
        self.text = text
        self.url = url
        self.sourceApp = sourceApp
        self.dataPath = dataPath
        self.timestamp = timestamp
        
        // Convert Any values to String for JSON serialization
        self.metadata = metadata.compactMapValues { value in
            if let string = value as? String {
                return string
            } else if let date = value as? Date {
                return ISO8601DateFormatter().string(from: date)
            } else {
                return String(describing: value)
            }
        }
    }
}

// MARK: - User Notifications Import
import UserNotifications