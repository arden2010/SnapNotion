//
//  Persistence.swift
//  SnapNotion
//
//  Created by A. C. on 8/22/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            // Handle the error gracefully in production
            let nsError = error as NSError
            print("❌ Preview data creation failed: \(nsError.localizedDescription)")
            // Continue without sample data for preview
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer
    
    // Background context for heavy operations
    lazy var backgroundContext: NSManagedObjectContext = {
        let context = container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return context
    }()

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "SnapNotion")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Handle persistent store loading errors gracefully
                print("❌ Core Data Error: Failed to load persistent store")
                print("Error: \(error.localizedDescription)")
                print("Store Description: \(storeDescription)")
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                
                // Try to recover by creating a fresh store
                if let storeURL = storeDescription.url {
                    do {
                        try FileManager.default.removeItem(at: storeURL)
                        print("🔄 Removed corrupted store, will create fresh store")
                    } catch {
                        print("⚠️ Could not remove corrupted store: \(error.localizedDescription)")
                    }
                }
            }
        })
        
        // Configure main view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        // Configure CloudKit settings
        configureCoreDataStack()
    }
    
    // MARK: - Core Data Configuration
    private func configureCoreDataStack() {
        // Configure CloudKit sync
        container.persistentStoreDescriptions.forEach { description in
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
        
        // Set up remote change notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(processRemoteStoreChanges),
            name: .NSPersistentStoreRemoteChange,
            object: nil
        )
    }
    
    @objc private func processRemoteStoreChanges(_ notification: Notification) {
        // Process remote changes on background queue to prevent UI blocking
        Task.detached {
            await self.container.viewContext.perform {
                // Refresh objects that might have been updated remotely
                self.container.viewContext.refreshAllObjects()
            }
        }
    }
    
    // MARK: - Safe Context Operations
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    let result = try block(self.backgroundContext)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func save(context: NSManagedObjectContext) async throws {
        guard context.hasChanges else { return }
        
        try await context.perform {
            try context.save()
        }
        
        // If this is background context, also save view context
        if context != container.viewContext {
            try await container.viewContext.perform {
                if self.container.viewContext.hasChanges {
                    try self.container.viewContext.save()
                }
            }
        }
    }
}
