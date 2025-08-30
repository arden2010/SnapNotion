//
//  ContentView.swift
//  SnapNotion
//
//  Created by A. C. on 8/22/25.
//

import SwiftUI
import CoreData
import UIKit
import Combine

struct ContentView: View {
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
                // Gmail-style Header
                GmailStyleHeader(searchText: $contentViewModel.searchText)
                
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

// MARK: - Gmail-Style Header
struct GmailStyleHeader: View {
    @Binding var searchText: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Top section with hamburger menu, search, and profile
            HStack(spacing: 12) {
                // Hamburger Menu
                Button(action: {}) {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("搜索智能内容", text: $searchText)
                        .textFieldStyle(.plain)
                        .claudeCodeStyle(.body)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                
                // Profile Avatar
                Button(action: {}) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 32, height: 32)
                        .overlay {
                            Text("J")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Color(.systemBackground))
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
        Group {
            if isLoading && contentItems.isEmpty {
                ProgressView("Loading content...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if contentItems.isEmpty {
                EmptyStateView()
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

// MARK: - Content Row (Gmail-style email row)
struct ContentRowView: View {
    let item: ContentItem
    let onFavoriteToggle: () -> Void
    let onDelete: () -> Void
    
    @State private var isFavorite: Bool
    
    init(item: ContentItem, onFavoriteToggle: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.item = item
        self.onFavoriteToggle = onFavoriteToggle
        self.onDelete = onDelete
        self._isFavorite = State(initialValue: item.isFavorite)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Source Icon/Avatar (like Gmail sender avatar)
            VStack {
                Circle()
                    .fill(item.sourceApp.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: item.sourceApp.icon)
                            .font(.system(size: 18))
                            .foregroundColor(item.sourceApp.color)
                    }
                
                // Processing status indicator
                if item.processingStatus != .completed {
                    Image(systemName: item.processingStatus.icon)
                        .font(.system(size: 10))
                        .foregroundColor(item.processingStatus.color)
                }
            }
            
            // Content Area
            VStack(alignment: .leading, spacing: 4) {
                // Title Row (like Gmail subject line)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .claudeCodeStyle(.bodyMedium)
                            .lineLimit(1)
                        
                        Text(item.sourceApp.displayName)
                            .claudeCodeStyle(.caption, color: .secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        // Timestamp
                        Text(item.timestamp, style: .time)
                            .claudeCodeStyle(.caption, color: .secondary)
                        
                        // Content type badge
                        Text(item.type.displayName)
                            .claudeCodeStyle(.caption, color: .tertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(item.type.color.opacity(0.1))
                            .foregroundColor(item.type.color)
                            .cornerRadius(4)
                    }
                }
                
                // Preview Text (like Gmail preview)
                Text(item.preview)
                    .claudeCodeStyle(.body, color: .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Attachment Preview Pills (like Gmail attachments)
                if !item.attachments.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(item.attachments) { attachment in
                                AttachmentPillView(attachment: attachment)
                            }
                        }
                    }
                }
            }
            
            // Favorite Star (like Gmail star)
            Button(action: { 
                isFavorite.toggle()
                onFavoriteToggle()
            }) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: 16))
                    .foregroundColor(isFavorite ? .yellow : .gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            // Handle tap to open content detail
        }
    }
}

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

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
        }
        .frame(width: 56, height: 56)
        .background(Color.blue)
        .cornerRadius(28)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Quick Capture View
struct QuickCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var clipboardMonitor: ClipboardMonitor
    @ObservedObject var screenshotDetector: ScreenCaptureDetector
    
    let onCameraCapture: () -> Void
    let onPhotoLibrary: () -> Void
    let onDocumentScan: () -> Void
    let onClipboardPaste: () -> Void
    let onScreenshotCapture: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("快速捕获")
                        .claudeCodeStyle(.header2)
                        .padding(.top)
                    
                    // Smart suggestions
                    if screenshotDetector.hasRecentScreenshot || 
                       clipboardMonitor.hasImageContent || 
                       clipboardMonitor.hasTextContent || 
                       clipboardMonitor.hasURLContent {
                        
                        SmartSuggestionsView(
                            clipboardMonitor: clipboardMonitor,
                            screenshotDetector: screenshotDetector,
                            onClipboardPaste: {
                                onClipboardPaste()
                                dismiss()
                            },
                            onScreenshotCapture: {
                                onScreenshotCapture()
                                dismiss()
                            }
                        )
                        
                        Divider()
                            .padding(.horizontal)
                    }
                    
                    // Capture options
                    VStack(spacing: 16) {
                        CaptureOptionButton(
                            icon: "camera",
                            title: "拍照捕获",
                            subtitle: "拍摄文档或场景",
                            color: .green
                        ) {
                            onCameraCapture()
                            dismiss()
                        }
                        
                        CaptureOptionButton(
                            icon: "photo.on.rectangle",
                            title: "照片库",
                            subtitle: "从照片库选择图片",
                            color: .blue
                        ) {
                            onPhotoLibrary()
                            dismiss()
                        }
                        
                        CaptureOptionButton(
                            icon: "doc.viewfinder",
                            title: "扫描文档",
                            subtitle: "扫描纸质文档",
                            color: .purple
                        ) {
                            onDocumentScan()
                            dismiss()
                        }
                        
                        CaptureOptionButton(
                            icon: "doc.on.clipboard",
                            title: "剪贴板内容",
                            subtitle: "处理剪贴板中的内容",
                            color: clipboardMonitor.hasImageContent || clipboardMonitor.hasTextContent ? .orange : .gray,
                            isEnabled: clipboardMonitor.hasImageContent || clipboardMonitor.hasTextContent || clipboardMonitor.hasURLContent
                        ) {
                            onClipboardPaste()
                            dismiss()
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CaptureOptionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void
    
    init(icon: String, title: String, subtitle: String, color: Color, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isEnabled ? color : .gray)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .claudeCodeStyle(.bodyMedium)
                        .foregroundColor(isEnabled ? .primary : .secondary)
                    Text(subtitle)
                        .claudeCodeStyle(.caption, color: .secondary)
                }
                
                Spacer()
                
                if isEnabled {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.tertiary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
    }
}

// MARK: - Preview Data
#if DEBUG
extension ContentItem {
    static let sampleData: [ContentItem] = [
        ContentItem(
            title: "AI技术前沿探讨",
            preview: "深入探讨人工智能在内容管理领域的最新应用，包括自然语言处理和知识图谱技术的发展趋势。",
            source: "Tech Blog",
            sourceApp: .safari,
            timestamp: Date().addingTimeInterval(-3600),
            type: .web,
            isFavorite: true,
            attachments: [
                AttachmentPreview(name: "AI_Report_2024", type: "PDF", size: 2048000, thumbnailPath: nil, fullPath: "/documents/ai_report.pdf"),
                AttachmentPreview(name: "Chart_Analysis", type: "PNG", size: 512000, thumbnailPath: nil, fullPath: "/images/chart.png")
            ],
            metadata: ContentMetadata(),
            processingStatus: .completed
        ),
        ContentItem(
            title: "产品需求文档",
            preview: "SnapNotion产品功能规划和用户需求分析，包含核心功能设计和技术架构说明。",
            source: "Product Team",
            sourceApp: .files,
            timestamp: Date().addingTimeInterval(-7200),
            type: .pdf,
            isFavorite: false,
            attachments: [
                AttachmentPreview(name: "PRD_v2.1", type: "PDF", size: 1024000, thumbnailPath: nil, fullPath: "/documents/prd.pdf")
            ],
            metadata: ContentMetadata(),
            processingStatus: .completed
        ),
        ContentItem(
            title: "会议记录摘要",
            preview: "技术架构讨论会议要点，包括数据库设计、API接口规范和安全考虑事项。",
            source: "Meeting Notes",
            sourceApp: .notes,
            timestamp: Date().addingTimeInterval(-10800),
            type: .text,
            isFavorite: true,
            attachments: [],
            metadata: ContentMetadata(),
            processingStatus: .completed
        ),
        ContentItem(
            title: "微信分享内容",
            preview: "来自微信的图片和文字内容，正在使用AI进行智能分析处理。",
            source: "WeChat Share",
            sourceApp: .wechat,
            timestamp: Date().addingTimeInterval(-1800),
            type: .image,
            isFavorite: false,
            attachments: [
                AttachmentPreview(name: "wechat_image", type: "JPG", size: 1536000, thumbnailPath: nil, fullPath: "/images/wechat.jpg")
            ],
            metadata: ContentMetadata(),
            processingStatus: .processing
        )
    ]
}
#endif

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}