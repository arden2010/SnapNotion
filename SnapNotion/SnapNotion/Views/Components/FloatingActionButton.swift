//
//  FloatingActionButton.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI

struct SmartFloatingActionButton: View {
    @StateObject private var clipboardMonitor = ClipboardMonitor()
    let onPaste: () -> Void
    let onLongPress: () -> Void
    
    @State private var isPressed = false
    @State private var showingPulse = false
    
    var body: some View {
        Button(action: {
            // Single tap action
            if clipboardMonitor.hasContent {
                onPaste()
                showPulseAnimation()
            } else {
                onLongPress()
            }
        }) {
            ZStack {
                // Base circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.phoenixOrange,
                                Color.phoenixOrange.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                // Pulse animation for clipboard activity
                if showingPulse {
                    Circle()
                        .stroke(Color.phoenixOrange.opacity(0.6), lineWidth: 2)
                        .frame(width: 56, height: 56)
                        .scaleEffect(showingPulse ? 1.4 : 1.0)
                        .opacity(showingPulse ? 0.0 : 0.8)
                        .animation(.easeOut(duration: 0.6), value: showingPulse)
                }
                
                // Dynamic icon based on clipboard state
                if clipboardMonitor.hasContent {
                    // Paste icon with small clipboard indicator
                    ZStack {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        // Small activity indicator
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .offset(x: 12, y: -12)
                            .opacity(0.9)
                    }
                } else {
                    // Default plus icon
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(color: .black.opacity(0.25), radius: isPressed ? 4 : 8, x: 0, y: isPressed ? 2 : 4)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            // Long press gesture for options menu
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    onLongPress()
                    impactFeedback()
                }
        )
        .simultaneousGesture(
            // Press animation
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
        .onAppear {
            // Monitor clipboard changes
            clipboardMonitor.startMonitoring()
        }
        .onDisappear {
            clipboardMonitor.stopMonitoring()
        }
        .onChange(of: clipboardMonitor.hasContent) { _, newValue in
            if newValue {
                showContentAvailableAnimation()
            }
        }
    }
    
    private func showPulseAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingPulse = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showingPulse = false
        }
    }
    
    private func showContentAvailableAnimation() {
        // Subtle bounce animation when clipboard content becomes available
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showingPulse = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showingPulse = false
        }
    }
    
    private func impactFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Content Options Menu
struct ContentOptionsMenu: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var clipboardMonitor = ClipboardMonitor()
    private let contentProcessor = ContentCaptureProcessor.shared
    @State private var showingProcessing = false
    @State private var processingMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Text("Add Content")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Choose how to capture and process your content")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
                
                // Content Options
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Clipboard option (only if content available)
                        if clipboardMonitor.hasContent {
                            QuickOption(
                                icon: "doc.on.clipboard",
                                title: "Paste from Clipboard",
                                subtitle: "Process copied content with AI",
                                color: .phoenixOrange,
                                isPrimary: true
                            ) {
                                processClipboardContent()
                            }
                        }
                        
                        QuickOption(
                            icon: "camera",
                            title: "Camera",
                            subtitle: "Capture documents and photos",
                            color: .blue
                        ) {
                            // TODO: Open camera
                            dismiss()
                        }
                        
                        QuickOption(
                            icon: "photo",
                            title: "Photo Library",
                            subtitle: "Process existing photos",
                            color: .green
                        ) {
                            // TODO: Open photo picker
                            dismiss()
                        }
                        
                        QuickOption(
                            icon: "doc.text",
                            title: "Text Note",
                            subtitle: "Create a new text note",
                            color: .orange
                        ) {
                            // TODO: Create text note
                            dismiss()
                        }
                        
                        QuickOption(
                            icon: "link",
                            title: "Web Link",
                            subtitle: "Save and analyze webpage",
                            color: .purple
                        ) {
                            // TODO: Add web link
                            dismiss()
                        }
                        
                        QuickOption(
                            icon: "square.and.arrow.down",
                            title: "Import File",
                            subtitle: "Import PDFs and documents",
                            color: .indigo
                        ) {
                            // TODO: Import file
                            dismiss()
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .overlay {
            if showingProcessing {
                ProcessingOverlay(message: processingMessage)
            }
        }
    }
    
    private func processClipboardContent() {
        guard let clipboardContent = clipboardMonitor.getClipboardContent() else {
            return
        }
        
        Task {
            await MainActor.run {
                showingProcessing = true
                processingMessage = "📋 Processing clipboard content..."
            }
            
            do {
                let result: ContentItem
                
                switch clipboardContent.type {
                case .text:
                    if let text = clipboardContent.text {
                        result = try await contentProcessor.processText(text, source: "Clipboard")
                    } else {
                        throw ContentProcessingError.aiProcessingFailed
                    }
                    
                case .image:
                    if let imageData = clipboardContent.data {
                        result = try await contentProcessor.processImage(imageData, source: "Clipboard")
                    } else {
                        throw ContentProcessingError.imageConversionFailed
                    }
                    
                case .web:
                    if let url = clipboardContent.url {
                        result = try await contentProcessor.processWebURL(url, source: "Clipboard")
                    } else {
                        throw ContentProcessingError.aiProcessingFailed
                    }
                    
                case .mixed, .pdf:
                    if let text = clipboardContent.text {
                        result = try await contentProcessor.processText(text, source: "Clipboard")
                    } else {
                        throw ContentProcessingError.aiProcessingFailed
                    }
                }
                
                await MainActor.run {
                    processingMessage = "✅ Content processed successfully!"
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.showingProcessing = false
                        self.dismiss()
                    }
                }
                
            } catch {
                await MainActor.run {
                    processingMessage = "❌ Failed to process: \(error.localizedDescription)"
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.showingProcessing = false
                    }
                }
            }
        }
    }
}

// MARK: - Quick Option View
struct QuickOption: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    var isPrimary: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(isPrimary ? 0.2 : 0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: isPrimary ? 22 : 20, weight: .medium))
                        .foregroundColor(color)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(isPrimary ? .headline : .body)
                        .fontWeight(isPrimary ? .semibold : .medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Chevron or primary indicator
                if isPrimary {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundColor(color)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPrimary ? color.opacity(0.05) : Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isPrimary ? color.opacity(0.3) : Color.clear, lineWidth: isPrimary ? 1.5 : 0)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Legacy Support
struct FloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.phoenixOrange)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SmartFloatingActionButton(
        onPaste: { print("Paste tapped") },
        onLongPress: { print("Long press") }
    )
}