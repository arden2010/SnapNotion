//
//  CloudKitSyncService.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import CloudKit
import CoreData
import Combine
import Foundation

// MARK: - CloudKit Sync Protocol

protocol CloudKitSyncServiceProtocol {
    func startSync() async throws
    func stopSync()
    func syncContent(_ content: ContentNode) async throws
    func deleteFromCloud(_ contentId: UUID) async throws
    func handleConflicts() async throws
}

// MARK: - Sync Status

enum SyncStatus {
    case idle
    case syncing
    case completed
    case failed(Error)
    case paused
}

enum ConflictResolutionStrategy {
    case useLocal
    case useRemote
    case merge
    case askUser
}

// MARK: - CloudKit Sync Service

@MainActor
class CloudKitSyncService: ObservableObject, CloudKitSyncServiceProtocol {
    
    static let shared = CloudKitSyncService()
    
    // MARK: - Published Properties
    @Published var syncStatus: SyncStatus = .idle
    @Published var syncProgress: Double = 0.0
    @Published var lastSyncDate: Date?
    @Published var isAccountAvailable: Bool = false
    @Published var pendingSyncItems: Int = 0
    @Published var conflicts: [SyncConflict] = []
    
    // MARK: - CloudKit Properties
    private let container: CKContainer
    private let database: CKDatabase
    private let privateDatabase: CKDatabase
    private let recordZone: CKRecordZone
    
    // MARK: - Core Data
    private let persistenceController = PersistenceController.shared
    private var context: NSManagedObjectContext {
        persistenceController.container.viewContext
    }
    
    // MARK: - Configuration
    private let maxRetryAttempts = 3
    private let batchSize = 100
    private let syncTimeoutInterval: TimeInterval = 300 // 5 minutes
    private var conflictResolutionStrategy: ConflictResolutionStrategy = .merge
    
    // MARK: - Internal State
    private var cancellables = Set<AnyCancellable>()
    private var syncTimer: Timer?
    private var isSyncing = false
    private var pendingOperations: [CKOperation] = []
    
    private init() {
        // Initialize CloudKit container
        container = CKContainer(identifier: "iCloud.com.snapnotion.app")
        database = container.publicCloudDatabase
        privateDatabase = container.privateCloudDatabase
        
        // Create custom record zone for better performance
        recordZone = CKRecordZone(zoneName: "SnapNotionZone")
        
        setupNotifications()
        checkAccountStatus()
        createRecordZoneIfNeeded()
    }
    
    // MARK: - Public API
    
    func startSync() async throws {
        guard !isSyncing else { return }
        guard isAccountAvailable else {
            throw SnapNotionError.cloudKitUnavailable
        }
        
        isSyncing = true
        syncStatus = .syncing
        syncProgress = 0.0
        
        do {
            // Perform initial sync operations
            try await performInitialSync()
            try await syncPendingChanges()
            try await handleConflicts()
            
            // Start periodic sync
            startPeriodicSync()
            
            syncStatus = .completed
            lastSyncDate = Date()
            
        } catch {
            syncStatus = .failed(error)
            isSyncing = false
            throw error
        }
        
        isSyncing = false
    }
    
    func stopSync() {
        syncTimer?.invalidate()
        syncTimer = nil
        
        // Cancel pending operations
        for operation in pendingOperations {
            operation.cancel()
        }
        pendingOperations.removeAll()
        
        isSyncing = false
        syncStatus = .idle
    }
    
    func syncContent(_ content: ContentNode) async throws {
        guard let contentId = content.id else {
            throw SnapNotionError.invalidContentID
        }
        
        let record = try createCKRecord(from: content)
        
        do {
            let savedRecord = try await privateDatabase.save(record)
            try await updateLocalContent(content, with: savedRecord)
            
        } catch let error as CKError {
            try await handleCloudKitError(error, for: contentId)
        }
    }
    
    func deleteFromCloud(_ contentId: UUID) async throws {
        let recordID = CKRecord.ID(recordName: contentId.uuidString, zoneID: recordZone.zoneID)
        
        do {
            _ = try await privateDatabase.deleteRecord(withID: recordID)
        } catch let error as CKError {
            if error.code == .unknownItem {
                // Record doesn't exist in cloud, which is fine
                return
            }
            throw error
        }
    }
    
    func handleConflicts() async throws {
        guard !conflicts.isEmpty else { return }
        
        for conflict in conflicts {
            try await resolveConflict(conflict)
        }
        
        conflicts.removeAll()
    }
    
    // MARK: - Initial Setup
    
    private func setupNotifications() {
        // Listen for iCloud account changes
        NotificationCenter.default.publisher(for: .CKAccountChanged)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.checkAccountStatus()
                }
            }
            .store(in: &cancellables)
        
        // Listen for remote changes
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .sink { [weak self] _ in
                Task {
                    try? await self?.handleRemoteChanges()
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkAccountStatus() {
        Task {
            do {
                let status = try await container.accountStatus()
                await MainActor.run {
                    isAccountAvailable = status == .available
                }
                
                if status != .available {
                    await MainActor.run {
                        syncStatus = .failed(SnapNotionError.cloudKitAccountUnavailable)
                    }
                }
            } catch {
                await MainActor.run {
                    isAccountAvailable = false
                    syncStatus = .failed(error)
                }
            }
        }
    }
    
    private func createRecordZoneIfNeeded() {
        Task {
            do {
                _ = try await privateDatabase.save(recordZone)
                print("📁 CloudKit record zone created/verified")
            } catch let error as CKError {
                if error.code != .serverRecordChanged {
                    print("⚠️ Failed to create record zone: \(error)")
                }
            }
        }
    }
    
    // MARK: - Sync Operations
    
    private func performInitialSync() async throws {
        // Fetch server changes first
        try await fetchServerChanges()
        
        // Then push local changes
        try await pushLocalChanges()
    }
    
    private func fetchServerChanges() async throws {
        let zoneID = recordZone.zoneID
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneID])
        
        var changedRecords: [CKRecord] = []
        var deletedRecordIDs: [CKRecord.ID] = []
        
        operation.recordChangedBlock = { record in
            changedRecords.append(record)
        }
        
        operation.recordWithIDWasDeletedBlock = { recordID, recordType in
            deletedRecordIDs.append(recordID)
        }
        
        operation.fetchRecordZoneChangesCompletionBlock = { [weak self] error in
            Task { @MainActor in
                if let error = error {
                    throw error
                }
                
                // Process changed records
                for record in changedRecords {
                    try? await self?.processServerRecord(record)
                }
                
                // Process deleted records
                for recordID in deletedRecordIDs {
                    try? await self?.processDeletedRecord(recordID)
                }
                
                self?.syncProgress += 0.5
            }
        }
        
        pendingOperations.append(operation)
        privateDatabase.add(operation)
        
        // Wait for completion
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.completionBlock = {
                continuation.resume()
            }
        }
    }
    
    private func pushLocalChanges() async throws {
        let request: NSFetchRequest<ContentNode> = ContentNode.fetchRequest()
        request.predicate = NSPredicate(format: "needsSync == true")
        
        do {
            let localChanges = try context.fetch(request)
            let totalChanges = localChanges.count
            
            for (index, content) in localChanges.enumerated() {
                try await syncContent(content)
                
                // Update progress
                syncProgress = 0.5 + (0.5 * Double(index + 1) / Double(totalChanges))
            }
            
        } catch {
            throw SnapNotionError.coreDataFetchFailed(entity: "ContentNode")
        }
    }
    
    private func syncPendingChanges() async throws {
        let request: NSFetchRequest<ContentNode> = ContentNode.fetchRequest()
        request.predicate = NSPredicate(format: "needsSync == true")
        
        do {
            let pendingItems = try context.fetch(request)
            pendingSyncItems = pendingItems.count
            
            let batches = pendingItems.chunked(into: batchSize)
            
            for batch in batches {
                try await processBatch(batch)
            }
            
            pendingSyncItems = 0
            
        } catch {
            throw SnapNotionError.contentProcessingFailed(underlying: error.localizedDescription)
        }
    }
    
    private func processBatch(_ items: [ContentNode]) async throws {
        let records = try items.compactMap { try? createCKRecord(from: $0) }
        
        do {
            let result = try await privateDatabase.modifyRecords(saving: records, deleting: [])
            
            // Update local items with saved records
            for (item, recordID) in zip(items, records.map { $0.recordID }) {
                if case .success(let record) = result.saveResults[recordID] {
                    try await updateLocalContent(item, with: record)
                }
            }
            
        } catch let error as CKError {
            try await handleBatchError(error, for: items)
        }
    }
    
    // MARK: - Record Conversion
    
    private func createCKRecord(from content: ContentNode) throws -> CKRecord {
        guard let contentId = content.id else {
            throw SnapNotionError.invalidContentID
        }
        
        let recordID = CKRecord.ID(recordName: contentId.uuidString, zoneID: recordZone.zoneID)
        let record = CKRecord(recordType: "ContentNode", recordID: recordID)
        
        // Map Core Data attributes to CloudKit record
        record["title"] = content.title
        record["contentText"] = content.contentText
        record["contentType"] = content.contentType
        record["sourceApp"] = content.sourceApp
        record["sourceURL"] = content.sourceURL
        record["isFavorite"] = content.isFavorite
        record["processingStatus"] = content.processingStatus
        record["aiConfidence"] = content.aiConfidence
        record["ocrText"] = content.ocrText
        record["createdAt"] = content.createdAt
        record["modifiedAt"] = content.modifiedAt
        
        // Handle binary data
        if let contentData = content.contentData {
            let asset = CKAsset(fileURL: try createTempFile(from: contentData))
            record["contentData"] = asset
        }
        
        if let semanticEmbedding = content.semanticEmbedding {
            let asset = CKAsset(fileURL: try createTempFile(from: semanticEmbedding))
            record["semanticEmbedding"] = asset
        }
        
        if let metadata = content.metadata {
            let asset = CKAsset(fileURL: try createTempFile(from: metadata))
            record["metadata"] = asset
        }
        
        return record
    }
    
    private func updateLocalContent(_ content: ContentNode, with record: CKRecord) async throws {
        content.needsSync = false
        content.cloudKitRecordName = record.recordID.recordName
        content.modifiedAt = Date()
        
        try context.save()
    }
    
    private func processServerRecord(_ record: CKRecord) async throws {
        guard let recordName = UUID(uuidString: record.recordID.recordName) else { return }
        
        // Check if local record exists
        let request: NSFetchRequest<ContentNode> = ContentNode.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", recordName as CVarArg)
        request.fetchLimit = 1
        
        do {
            let existingRecords = try context.fetch(request)
            
            if let existingRecord = existingRecords.first {
                // Check for conflicts
                if hasConflict(localRecord: existingRecord, serverRecord: record) {
                    let conflict = SyncConflict(
                        contentId: recordName,
                        localRecord: existingRecord,
                        serverRecord: record,
                        conflictType: .dataConflict
                    )
                    conflicts.append(conflict)
                } else {
                    // Update local record with server data
                    try await updateLocalRecord(existingRecord, with: record)
                }
            } else {
                // Create new local record from server data
                try await createLocalRecord(from: record)
            }
            
        } catch {
            throw SnapNotionError.coreDataFetchFailed(entity: "ContentNode")
        }
    }
    
    private func processDeletedRecord(_ recordID: CKRecord.ID) async throws {
        guard let recordName = UUID(uuidString: recordID.recordName) else { return }
        
        let request: NSFetchRequest<ContentNode> = ContentNode.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", recordName as CVarArg)
        request.fetchLimit = 1
        
        do {
            let existingRecords = try context.fetch(request)
            if let existingRecord = existingRecords.first {
                context.delete(existingRecord)
                try context.save()
            }
        } catch {
            throw SnapNotionError.coreDataFetchFailed(entity: "ContentNode")
        }
    }
    
    // MARK: - Conflict Resolution
    
    private func hasConflict(localRecord: ContentNode, serverRecord: CKRecord) -> Bool {
        // Check modification dates
        let localModified = localRecord.modifiedAt ?? Date.distantPast
        let serverModified = serverRecord.modificationDate ?? Date.distantPast
        
        // If both records were modified recently, there might be a conflict
        return abs(localModified.timeIntervalSince(serverModified)) > 60 // 1 minute threshold
    }
    
    private func resolveConflict(_ conflict: SyncConflict) async throws {
        switch conflictResolutionStrategy {
        case .useLocal:
            try await syncContent(conflict.localRecord)
            
        case .useRemote:
            try await updateLocalRecord(conflict.localRecord, with: conflict.serverRecord)
            
        case .merge:
            try await mergeRecords(local: conflict.localRecord, server: conflict.serverRecord)
            
        case .askUser:
            // This would present a UI to the user to resolve the conflict
            // For now, default to merge
            try await mergeRecords(local: conflict.localRecord, server: conflict.serverRecord)
        }
    }
    
    private func mergeRecords(local: ContentNode, server: CKRecord) async throws {
        // Implement smart merging logic
        // Use the most recent modification date for each field
        
        let localModified = local.modifiedAt ?? Date.distantPast
        let serverModified = server.modificationDate ?? Date.distantPast
        
        if serverModified > localModified {
            // Server is newer, update most fields from server
            try await updateLocalRecord(local, with: server)
        } else {
            // Local is newer, push to server
            try await syncContent(local)
        }
    }
    
    // MARK: - Error Handling
    
    private func handleCloudKitError(_ error: CKError, for contentId: UUID) async throws {
        switch error.code {
        case .networkFailure, .networkUnavailable:
            // Retry later
            throw SnapNotionError.networkConnectionFailed
            
        case .quotaExceeded:
            throw SnapNotionError.cloudKitQuotaExceeded
            
        case .zoneBusy:
            // Wait and retry
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            throw SnapNotionError.cloudKitZoneBusy
            
        case .serverRecordChanged:
            // Handle conflict
            try await handleServerRecordChanged(error, for: contentId)
            
        default:
            throw SnapNotionError.cloudKitSyncFailed(underlying: error.localizedDescription)
        }
    }
    
    private func handleBatchError(_ error: CKError, for items: [ContentNode]) async throws {
        if let partialErrors = error.userInfo[CKPartialErrorsByItemIDKey] as? [CKRecord.ID: Error] {
            // Handle individual item errors
            for (recordID, itemError) in partialErrors {
                if let uuid = UUID(uuidString: recordID.recordName),
                   let item = items.first(where: { $0.id == uuid }) {
                    try? await handleCloudKitError(itemError as? CKError ?? CKError(.internalError), for: uuid)
                }
            }
        } else {
            throw error
        }
    }
    
    private func handleServerRecordChanged(_ error: CKError, for contentId: UUID) async throws {
        // Extract server record from error
        if let serverRecord = error.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord {
            // Create conflict for resolution
            let request: NSFetchRequest<ContentNode> = ContentNode.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", contentId as CVarArg)
            request.fetchLimit = 1
            
            if let localRecord = try context.fetch(request).first {
                let conflict = SyncConflict(
                    contentId: contentId,
                    localRecord: localRecord,
                    serverRecord: serverRecord,
                    conflictType: .serverRecordChanged
                )
                conflicts.append(conflict)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func startPeriodicSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in // 5 minutes
            Task {
                try? await self.syncPendingChanges()
            }
        }
    }
    
    private func handleRemoteChanges() async throws {
        // This is called when Core Data detects remote changes
        // Trigger a sync to get the latest changes
        try await fetchServerChanges()
    }
    
    private func createTempFile(from data: Data) throws -> URL {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("data")
        
        try data.write(to: tempURL)
        return tempURL
    }
    
    private func updateLocalRecord(_ local: ContentNode, with server: CKRecord) async throws {
        // Update local record with server data
        local.title = server["title"] as? String
        local.contentText = server["contentText"] as? String
        local.contentType = server["contentType"] as? String
        local.sourceApp = server["sourceApp"] as? String
        local.sourceURL = server["sourceURL"] as? String
        local.isFavorite = server["isFavorite"] as? Bool ?? false
        local.processingStatus = server["processingStatus"] as? String
        local.aiConfidence = server["aiConfidence"] as? Double ?? 0.0
        local.ocrText = server["ocrText"] as? String
        local.modifiedAt = server.modificationDate
        local.cloudKitRecordName = server.recordID.recordName
        local.needsSync = false
        
        try context.save()
    }
    
    private func createLocalRecord(from server: CKRecord) async throws {
        guard let recordName = UUID(uuidString: server.recordID.recordName) else { return }
        
        let content = ContentNode(context: context)
        content.id = recordName
        content.title = server["title"] as? String
        content.contentText = server["contentText"] as? String
        content.contentType = server["contentType"] as? String
        content.sourceApp = server["sourceApp"] as? String
        content.sourceURL = server["sourceURL"] as? String
        content.isFavorite = server["isFavorite"] as? Bool ?? false
        content.processingStatus = server["processingStatus"] as? String
        content.aiConfidence = server["aiConfidence"] as? Double ?? 0.0
        content.ocrText = server["ocrText"] as? String
        content.createdAt = server.creationDate
        content.modifiedAt = server.modificationDate
        content.cloudKitRecordName = server.recordID.recordName
        content.needsSync = false
        
        try context.save()
    }
}

// MARK: - Supporting Types

struct SyncConflict {
    let contentId: UUID
    let localRecord: ContentNode
    let serverRecord: CKRecord
    let conflictType: ConflictType
    
    enum ConflictType {
        case dataConflict
        case serverRecordChanged
        case deletionConflict
    }
}

// MARK: - Array Extension

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

