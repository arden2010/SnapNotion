//
//  LegacyContentView.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI
import CoreData
import UIKit
import Combine

struct LegacyContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var contentViewModel = ContentViewModel()
    @StateObject private var clipboardMonitor = ClipboardMonitor()
    @StateObject private var screenshotDetector = ScreenCaptureDetector()
    
    @State private var showingCaptureSheet = false
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var showingDocumentScanner = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    var body: some View {
        ZStack {
            // Main Content Area
            VStack(spacing: 0) {
                // Filter Pills (like Gmail's Primary/Social/Promotions)
                FilterPillsView(selectedFilter: $contentViewModel.selectedFilter)
                
                // Content List
                ContentListView(
                    contentItems: contentViewModel.filteredItems,
                    isLoading: contentViewModel.isLoading,
                    onFavoriteToggle: { item in
                        contentViewModel.toggleFavorite(for: item)
                    },
                    onDelete: { item in
                        contentViewModel.deleteItem(item)
                    }
                )
                .refreshable {
                    await contentViewModel.refreshContent()
                }
            }
            
            // Floating Action Button (Gmail-style)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton {
                        showingCaptureSheet = true
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 100) // Account for tab bar
                }
            }
        }
        .sheet(isPresented: $showingCaptureSheet) {
            QuickCaptureView(
                clipboardMonitor: clipboardMonitor,
                screenshotDetector: screenshotDetector,
                onCameraCapture: { showingCamera = true },
                onPhotoLibrary: { showingPhotoLibrary = true },
                onDocumentScan: { showingDocumentScanner = true },
                onClipboardPaste: { handleClipboardContent() },
                onScreenshotCapture: { handleRecentScreenshot() }
            )
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraCaptureView(
                isPresented: $showingCamera,
                onImageCaptured: { data in handleCapturedImage(data, source: .camera) },
                onError: { error in showError(error) }
            )
        }
        .sheet(isPresented: $showingPhotoLibrary) {
            PhotoLibraryPicker(
                isPresented: $showingPhotoLibrary,
                onImageSelected: { data in handleCapturedImage(data, source: .photos) },
                onError: { error in showError(error) }
            )
        }
        .fullScreenCover(isPresented: $showingDocumentScanner) {
            if #available(iOS 13.0, *) {
                DocumentScannerView(
                    isPresented: $showingDocumentScanner,
                    onDocumentScanned: { dataArray in handleScannedDocuments(dataArray) },
                    onError: { error in showError(error) }
                )
            }
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            setupNotifications()
        }
    }
    
    // MARK: - Private Methods
    private func handleCapturedImage(_ data: Data, source: AppSource) {
        let sharedContent = SharedContent(
            type: .image,
            data: data,
            text: nil,
            url: nil,
            sourceApp: source,
            metadata: ["captureMethod": "direct", "timestamp": Date().timeIntervalSince1970]
        )
        
        Task {
            await contentViewModel.processSharedContent(sharedContent)
        }
    }
    
    private func handleScannedDocuments(_ dataArray: [Data]) {
        for data in dataArray {
            let sharedContent = SharedContent(
                type: .image,
                data: data,
                text: nil,
                url: nil,
                sourceApp: .camera,
                metadata: ["captureMethod": "document_scan", "timestamp": Date().timeIntervalSince1970]
            )
            
            Task {
                await contentViewModel.processSharedContent(sharedContent)
            }
        }
    }
    
    private func handleClipboardContent() {
        guard let content = clipboardMonitor.getClipboardContent() else {
            showError(NSError(domain: "SnapNotion", code: -1, userInfo: [NSLocalizedDescriptionKey: "No content found in clipboard"]))
            return
        }
        
        Task {
            await contentViewModel.processSharedContent(content)
        }
    }
    
    private func handleRecentScreenshot() {
        Task {
            if let screenshotData = await screenshotDetector.getLatestScreenshot() {
                let sharedContent = SharedContent(
                    type: .image,
                    data: screenshotData,
                    text: nil,
                    url: nil,
                    sourceApp: .photos,
                    metadata: ["captureMethod": "screenshot", "timestamp": Date().timeIntervalSince1970]
                )
                
                await contentViewModel.processSharedContent(sharedContent)
            } else {
                showError(NSError(domain: "SnapNotion", code: -1, userInfo: [NSLocalizedDescriptionKey: "No recent screenshot found"]))
            }
        }
    }
    
    private func showError(_ error: Error) {
        errorMessage = error.localizedDescription
        showingErrorAlert = true
    }
    
    private func setupNotifications() {
        // Listen for shared content notifications
        NotificationCenter.default.addObserver(
            forName: .init("SharedContentReceived"),
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let contentData = userInfo["content"] as? Data,
               let sharedContent = try? JSONDecoder().decode(SharedContent.self, from: contentData) {
                
                Task {
                    await contentViewModel.processSharedContent(sharedContent)
                }
            }
        }
    }
}

// MARK: - Filter Pills View
struct FilterPillsView: View {
    @Binding var selectedFilter: ContentFilter
    
    let filters = ContentFilter.allCases
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(filters, id: \.id) { filter in
                    FilterPill(
                        title: filter.displayName,
                        icon: filter.icon,
                        isSelected: selectedFilter.id == filter.id
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }
}

struct FilterPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .claudeCodeStyle(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - Content List View
struct ContentListView: View {
    let contentItems: [ContentItem]
    let isLoading: Bool
    let onFavoriteToggle: (ContentItem) -> Void
    let onDelete: (ContentItem) -> Void
    
    var body: some View {
        VStack {
            if isLoading && contentItems.isEmpty {
                ProgressView("Loading content...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if contentItems.isEmpty {
                Text("No content yet")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(contentItems) { item in
                            ContentRowView(
                                item: item,
                                onFavoriteToggle: { onFavoriteToggle(item) },
                                onDelete: { onDelete(item) }
                            )
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - ContentRowView removed to avoid duplicate declaration
// ContentRowView is now defined in Views/Components/ContentRowView.swift

// MARK: - Attachment Pill View
struct AttachmentPillView: View {
    let attachment: AttachmentPreview
    
    var body: some View {
        HStack(spacing: 4) {
            // File type icon
            Image(systemName: iconForFileType(attachment.type))
                .font(.system(size: 12))
                .foregroundColor(.white)
            
            Text(attachment.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(colorForFileType(attachment.type))
        .cornerRadius(12)
    }
    
    private func iconForFileType(_ type: String) -> String {
        switch type.uppercased() {
        case "PDF": return "doc.fill"
        case "PNG", "JPG", "JPEG": return "photo.fill"
        default: return "doc.fill"
        }
    }
    
    private func colorForFileType(_ type: String) -> Color {
        switch type.uppercased() {
        case "PDF": return .red
        case "PNG", "JPG", "JPEG": return .blue
        default: return .gray
        }
    }
}

// MARK: - FloatingActionButton moved to dedicated file
// FloatingActionButton is now in Views/Components/FloatingActionButton.swift

// MARK: - QuickCaptureView moved to dedicated file
// QuickCaptureView is now in Views/Components/QuickCaptureView.swift

#Preview {
    LegacyContentView()
}
