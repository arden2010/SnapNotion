//
//  ContentNode+CloudKit.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import Foundation
import CloudKit
import CoreData

// MARK: - ContentNode CloudKit Extension
extension ContentNode {
    
    /// Indicates whether this content node needs to be synced to CloudKit
    var needsSync: Bool {
        get {
            return primitiveValue(forKey: "needsSync") as? Bool ?? false
        }
        set {
            setPrimitiveValue(newValue, forKey: "needsSync")
        }
    }
    
    /// The CloudKit record name for this content node
    var cloudKitRecordName: String? {
        get {
            return primitiveValue(forKey: "cloudKitRecordName") as? String
        }
        set {
            setPrimitiveValue(newValue, forKey: "cloudKitRecordName")
        }
    }
    
    /// The CloudKit record change tag for conflict resolution
    var cloudKitRecordChangeTag: String? {
        get {
            return primitiveValue(forKey: "cloudKitRecordChangeTag") as? String
        }
        set {
            setPrimitiveValue(newValue, forKey: "cloudKitRecordChangeTag")
        }
    }
    
    /// Timestamp of last CloudKit sync
    var lastCloudKitSync: Date? {
        get {
            return primitiveValue(forKey: "lastCloudKitSync") as? Date
        }
        set {
            setPrimitiveValue(newValue, forKey: "lastCloudKitSync")
        }
    }
    
    // MARK: - CloudKit Helper Methods
    
    /// Marks this content node as needing sync
    func markForSync() {
        needsSync = true
        modifiedAt = Date()
    }
    
    /// Marks this content node as synced
    func markAsSynced(recordName: String, changeTag: String) {
        needsSync = false
        cloudKitRecordName = recordName
        cloudKitRecordChangeTag = changeTag
        lastCloudKitSync = Date()
    }
    
    /// Gets the CloudKit record ID for this content node
    var recordID: CKRecord.ID {
        let recordName = cloudKitRecordName ?? id?.uuidString ?? UUID().uuidString
        let zoneID = CKRecordZone.ID(zoneName: "SnapNotionZone", ownerName: CKCurrentUserDefaultName)
        return CKRecord.ID(recordName: recordName, zoneID: zoneID)
    }
}

// MARK: - Core Data Model Updates
// Note: These properties should be added to the Core Data model as optional attributes:
// - needsSync: Boolean (default: false)
// - cloudKitRecordName: String (optional)
// - cloudKitRecordChangeTag: String (optional) 
// - lastCloudKitSync: Date (optional)