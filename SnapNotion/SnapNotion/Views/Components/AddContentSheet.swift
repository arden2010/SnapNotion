//
//  AddContentSheet.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI
import UIKit
import AVFoundation

struct AddContentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var contentManager = ContentManager.shared
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var showingDocumentPicker = false
    @State private var showingTextEditor = false
    @State private var showingWebLinkDialog = false
    @State private var textInput = ""
    @State private var webURLInput = ""
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Capture Content")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("SnapNotion automatically detects and processes your screenshots")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical)
                    
                    // Primary Feature - Automatic Screenshot Detection
                    VStack(spacing: 16) {
                        AutoScreenshotInfoCard()
                        
                        Divider()
                            .padding(.horizontal)
                        
                        Text("Other Options")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        // Other Content Options
                        VStack(spacing: 12) {
                            AddContentOption(
                                icon: "camera",
                                title: "Camera",
                                subtitle: "Take photo of documents, whiteboards, etc.",
                                color: .blue
                            ) {
                                openCamera()
                            }
                            
                            AddContentOption(
                                icon: "photo",
                                title: "Photo Library",
                                subtitle: "Process existing photos with AI",
                                color: .green
                            ) {
                                openPhotoPicker()
                            }
                        
                            AddContentOption(
                                icon: "doc.text",
                                title: "Text Note",
                                subtitle: "Create new text content manually",
                                color: .orange
                            ) {
                                showingTextEditor = true
                            }
                            
                            AddContentOption(
                                icon: "link",
                                title: "Web Link",
                                subtitle: "Save and analyze website content",
                                color: .purple
                            ) {
                                showingWebLinkDialog = true
                            }
                            
                            
                            AddContentOption(
                                icon: "square.and.arrow.down",
                                title: "Import File",
                                subtitle: "Import and analyze PDFs, documents",
                                color: .indigo
                            ) {
                                showingDocumentPicker = true
                            }
                            
                            AddContentOption(
                                icon: "doc.on.clipboard",
                                title: "From Clipboard",
                                subtitle: "Process content from clipboard",
                                color: .red
                            ) {
                                Task {
                                    await processClipboard()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView { capturedImage in
                Task {
                    await processImageFromCamera(capturedImage)
                }
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerView { selectedImage in
                Task {
                    await processImageFromPhotoLibrary(selectedImage)
                }
            }
        }
        .sheet(isPresented: $showingTextEditor) {
            TextEditorSheet(text: $textInput) { text in
                Task {
                    await processTextInput(text)
                }
            }
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPickerView { url in
                Task {
                    await processDocumentFile(url)
                }
            }
        }
        .alert("Add Web Link", isPresented: $showingWebLinkDialog) {
            TextField("Enter URL", text: $webURLInput)
            Button("Cancel", role: .cancel) { }
            Button("Add") {
                Task {
                    await processWebURL(webURLInput)
                }
            }
        } message: {
            Text("Enter a web URL to save and analyze")
        }
        .overlay {
            if isProcessing {
                ProcessingOverlay(message: "Processing content...")
            }
        }
    }
    
    // MARK: - Camera & Photo Methods
    private func openCamera() {
        cameraManager.requestCameraPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    self.showingCamera = true
                } else {
                    // Show permission alert
                }
            }
        }
    }
    
    private func openPhotoPicker() {
        showingPhotoPicker = true
    }
    
    // MARK: - Content Processing Methods
    
    private func processImageFromCamera(_ image: UIImage) async {
        isProcessing = true
        do {
            let _ = try await contentManager.createContentFromCamera(image: image)
            await MainActor.run {
                isProcessing = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                isProcessing = false
                // Handle error appropriately
            }
        }
    }
    
    private func processImageFromPhotoLibrary(_ image: UIImage) async {
        isProcessing = true
        do {
            let _ = try await contentManager.createContentFromPhotoLibrary(image: image)
            await MainActor.run {
                isProcessing = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                isProcessing = false
                // Handle error appropriately
            }
        }
    }
    
    private func processTextInput(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isProcessing = true
        do {
            let _ = try await contentManager.createContentFromText(text)
            await MainActor.run {
                isProcessing = false
                textInput = ""
                dismiss()
            }
        } catch {
            await MainActor.run {
                isProcessing = false
                // Handle error appropriately
            }
        }
    }
    
    private func processWebURL(_ urlString: String) async {
        guard let url = URL(string: urlString), !urlString.isEmpty else { return }
        
        isProcessing = true
        do {
            let _ = try await contentManager.createContentFromURL(url)
            await MainActor.run {
                isProcessing = false
                webURLInput = ""
                dismiss()
            }
        } catch {
            await MainActor.run {
                isProcessing = false
                // Handle error appropriately
            }
        }
    }
    
    private func processDocumentFile(_ url: URL) async {
        isProcessing = true
        do {
            let _ = try await contentManager.createContentFromFile(at: url)
            await MainActor.run {
                isProcessing = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                isProcessing = false
                // Handle error appropriately
            }
        }
    }
    
    private func processClipboard() async {
        isProcessing = true
        do {
            if let _ = try await contentManager.createContentFromClipboard() {
                await MainActor.run {
                    isProcessing = false
                    dismiss()
                }
            } else {
                await MainActor.run {
                    isProcessing = false
                    // No clipboard content to process
                }
            }
        } catch {
            await MainActor.run {
                isProcessing = false
                // Handle error appropriately
            }
        }
    }
}

// MARK: - Primary Content Option (Highlighted)
struct AddContentPrimaryOption: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let isRecommended: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Large Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: icon)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(color)
                }
                
                // Text Content
                VStack(spacing: 6) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                
                if isRecommended {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                        Text("Most Popular")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [color.opacity(0.05), color.opacity(0.02)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct AddContentOption: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Processing Overlay
struct ProcessingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Animated Processing Indicator
                ZStack {
                    Circle()
                        .stroke(Color.phoenixOrange.opacity(0.3), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Color.phoenixOrange, lineWidth: 4)
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .rotationEffect(.degrees(360))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: message)
                }
                
                VStack(spacing: 8) {
                    Text(message)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("This may take a few seconds...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Auto Screenshot Info Card
struct AutoScreenshotInfoCard: View {
    var body: some View {
        VStack(spacing: 16) {
            // Large Screenshot Icon
            ZStack {
                Circle()
                    .fill(Color.phoenixOrange.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "iphone.and.arrow.forward")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.phoenixOrange)
            }
            
            // Instruction Steps
            VStack(spacing: 12) {
                Text("🔥 Smart Screenshot Processing")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                VStack(spacing: 8) {
                    HStack {
                        Text("1.")
                            .font(.headline)
                            .foregroundColor(.phoenixOrange)
                            .frame(width: 24)
                        
                        Text("Take a screenshot using iPhone's standard method")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("2.")
                            .font(.headline)
                            .foregroundColor(.phoenixOrange)
                            .frame(width: 24)
                        
                        Text("SnapNotion automatically detects and processes it")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("3.")
                            .font(.headline)
                            .foregroundColor(.phoenixOrange)
                            .frame(width: 24)
                        
                        Text("AI extracts text, creates tasks, organizes content")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
                
                // Screenshot Method Reminder
                VStack(spacing: 8) {
                    Text("📱 How to take a screenshot:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        Label("Side Button + Volume Up", systemImage: "button.programmable")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("or")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Label("AssistiveTouch", systemImage: "hand.tap")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text("Monitoring Active")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.phoenixOrange.opacity(0.05), Color.phoenixOrange.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.phoenixOrange.opacity(0.3), lineWidth: 2)
        )
    }
}

#Preview {
    AddContentSheet()
}