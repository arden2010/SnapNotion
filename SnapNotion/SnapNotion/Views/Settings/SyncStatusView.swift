//
//  SyncStatusView.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI

struct SyncStatusView: View {
    @StateObject private var syncService = CloudKitSyncService.shared
    @State private var showingConflictResolution = false
    @State private var showingErrorDetails = false
    @State private var errorDetails: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Sync Status Header
            syncStatusHeader
            
            // Sync Details
            syncDetailsView
            
            // Conflict Resolution
            if !syncService.conflicts.isEmpty {
                conflictSection
            }
            
            // Sync Actions
            syncActionsView
        }
        .navigationTitle("Sync Status")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingConflictResolution) {
            ConflictResolutionView(conflicts: $syncService.conflicts)
        }
        .alert("Sync Error", isPresented: $showingErrorDetails) {
            Button("OK") { }
        } message: {
            Text(errorDetails)
        }
    }
    
    // MARK: - Sync Status Header
    
    private var syncStatusHeader: some View {
        VStack(spacing: 16) {
            // Status Icon and Title
            HStack(spacing: 16) {
                statusIcon
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(statusTitle)
                        .claudeCodeStyle(.header3, color: .primary)
                    
                    Text(statusSubtitle)
                        .claudeCodeStyle(.caption, color: .secondary)
                }
                
                Spacer()
                
                if case .syncing = syncService.syncStatus {
                    ProgressView()
                        .scaleEffect(0.9)
                }
            }
            
            // Progress Bar (when syncing)
            if case .syncing = syncService.syncStatus {
                VStack(spacing: 8) {
                    ProgressView(value: syncService.syncProgress)
                        .tint(.phoenixOrange)
                    
                    HStack {
                        Text("\(Int(syncService.syncProgress * 100))% Complete")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if syncService.pendingSyncItems > 0 {
                            Text("\(syncService.pendingSyncItems) items remaining")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(statusBackgroundColor)
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
    
    // MARK: - Sync Details
    
    private var syncDetailsView: some View {
        VStack(spacing: 0) {
            // Account Status
            accountStatusRow
            
            Divider()
                .padding(.leading, 44)
            
            // Last Sync
            lastSyncRow
            
            Divider()
                .padding(.leading, 44)
            
            // Storage Info
            storageInfoRow
        }
        .background(Color(.systemBackground))
    }
    
    private var accountStatusRow: some View {
        HStack(spacing: 16) {
            Image(systemName: "icloud")
                .font(.title2)
                .foregroundColor(syncService.isAccountAvailable ? .blue : .red)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("iCloud Account")
                    .font(.body)
                
                Text(syncService.isAccountAvailable ? "Available" : "Not Available")
                    .font(.caption)
                    .foregroundColor(syncService.isAccountAvailable ? .green : .red)
            }
            
            Spacer()
            
            if !syncService.isAccountAvailable {
                Button("Settings") {
                    openSettings()
                }
                .foregroundColor(.blue)
            }
        }
        .padding()
    }
    
    private var lastSyncRow: some View {
        HStack(spacing: 16) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.title2)
                .foregroundColor(.secondary)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Last Sync")
                    .font(.body)
                
                if let lastSync = syncService.lastSyncDate {
                    Text(lastSync, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Never")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var storageInfoRow: some View {
        HStack(spacing: 16) {
            Image(systemName: "externaldrive.connected.to.line.below")
                .font(.title2)
                .foregroundColor(.secondary)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("iCloud Storage")
                    .font(.body)
                
                Text("Checking...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Manage") {
                openCloudStorage()
            }
            .foregroundColor(.blue)
        }
        .padding()
    }
    
    // MARK: - Conflict Section
    
    private var conflictSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text("Sync Conflicts")
                    .claudeCodeStyle(.header3, color: .primary)
                
                Spacer()
                
                Text("\(syncService.conflicts.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
            }
            
            Text("Some items have conflicting changes that need to be resolved.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Resolve Conflicts") {
                showingConflictResolution = true
            }
            .buttonStyle(.bordered)
            .foregroundColor(.orange)
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .overlay(
            Rectangle()
                .fill(Color.orange.opacity(0.3))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
    
    // MARK: - Sync Actions
    
    private var syncActionsView: some View {
        VStack(spacing: 16) {
            // Primary Actions
            VStack(spacing: 12) {
                if case .idle = syncService.syncStatus {
                    Button("Sync Now") {
                        performSync()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!syncService.isAccountAvailable)
                    .frame(maxWidth: .infinity)
                } else if case .syncing = syncService.syncStatus {
                    Button("Cancel Sync") {
                        syncService.stopSync()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                }
                
                if case .failed(let error) = syncService.syncStatus {
                    Button("Retry Sync") {
                        performSync()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    
                    Button("Show Error Details") {
                        errorDetails = error.localizedDescription
                        showingErrorDetails = true
                    }
                    .foregroundColor(.red)
                }
            }
            
            // Secondary Actions
            HStack(spacing: 16) {
                Button("Reset Sync") {
                    resetSync()
                }
                .foregroundColor(.red)
                
                Spacer()
                
                Button("Export Data") {
                    exportData()
                }
                .foregroundColor(.blue)
            }
        }
        .padding()
    }
    
    // MARK: - Computed Properties
    
    private var statusIcon: some View {
        Group {
            switch syncService.syncStatus {
            case .idle:
                Image(systemName: "icloud")
                    .foregroundColor(.secondary)
            case .syncing:
                Image(systemName: "icloud.and.arrow.up")
                    .foregroundColor(.blue)
            case .completed:
                Image(systemName: "icloud.and.arrow.up")
                    .foregroundColor(.green)
            case .failed:
                Image(systemName: "icloud.slash")
                    .foregroundColor(.red)
            case .paused:
                Image(systemName: "pause.circle")
                    .foregroundColor(.orange)
            }
        }
        .font(.title)
    }
    
    private var statusTitle: String {
        switch syncService.syncStatus {
        case .idle: return "Ready to Sync"
        case .syncing: return "Syncing..."
        case .completed: return "Up to Date"
        case .failed: return "Sync Failed"
        case .paused: return "Sync Paused"
        }
    }
    
    private var statusSubtitle: String {
        switch syncService.syncStatus {
        case .idle:
            if let lastSync = syncService.lastSyncDate {
                return "Last synced \(lastSync.formatted(.relative(presentation: .named)))"
            } else {
                return "Never synced"
            }
        case .syncing:
            return "Synchronizing your data with iCloud"
        case .completed:
            return "All changes have been synchronized"
        case .failed(let error):
            return "Error: \(error.localizedDescription)"
        case .paused:
            return "Sync has been temporarily paused"
        }
    }
    
    private var statusBackgroundColor: Color {
        switch syncService.syncStatus {
        case .idle: return Color(.systemGray6)
        case .syncing: return Color.blue.opacity(0.1)
        case .completed: return Color.green.opacity(0.1)
        case .failed: return Color.red.opacity(0.1)
        case .paused: return Color.orange.opacity(0.1)
        }
    }
    
    // MARK: - Actions
    
    private func performSync() {
        Task {
            do {
                try await syncService.startSync()
            } catch {
                // Error is handled by the service
            }
        }
    }
    
    private func resetSync() {
        syncService.stopSync()
        // Additional reset logic would go here
    }
    
    private func exportData() {
        // Implement data export functionality
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func openCloudStorage() {
        // Open iCloud storage management
        if let url = URL(string: "prefs:root=APPLE_ACCOUNT&path=ICLOUD_SERVICE") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Conflict Resolution View

struct ConflictResolutionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var conflicts: [SyncConflict]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(conflicts.indices, id: \.self) { index in
                    ConflictRowView(conflict: conflicts[index]) { resolution in
                        // Handle conflict resolution
                        conflicts.remove(at: index)
                    }
                }
            }
            .navigationTitle("Resolve Conflicts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ConflictRowView: View {
    let conflict: SyncConflict
    let onResolution: (ConflictResolutionStrategy) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(conflict.localRecord.title ?? "Untitled")
                .font(.headline)
            
            Text("This item was modified on multiple devices")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Button("Use Local") {
                    onResolution(.useLocal)
                }
                .buttonStyle(.bordered)
                
                Button("Use Remote") {
                    onResolution(.useRemote)
                }
                .buttonStyle(.bordered)
                
                Button("Merge") {
                    onResolution(.merge)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    SyncStatusView()
}