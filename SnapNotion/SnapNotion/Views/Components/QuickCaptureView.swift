//
//  QuickCaptureView.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI

struct QuickCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    let clipboardMonitor: ClipboardMonitor
    let screenshotDetector: ScreenCaptureDetector
    let onCameraCapture: () -> Void
    let onPhotoLibrary: () -> Void
    let onDocumentScan: () -> Void
    let onClipboardPaste: () -> Void
    let onScreenshotCapture: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Quick Capture")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    CaptureOptionButton(
                        icon: "camera",
                        title: "Take Photo",
                        subtitle: "Capture with camera",
                        color: .blue,
                        action: {
                            dismiss()
                            onCameraCapture()
                        }
                    )
                    
                    CaptureOptionButton(
                        icon: "photo.on.rectangle",
                        title: "Photo Library",
                        subtitle: "Choose from photos",
                        color: .green,
                        action: {
                            dismiss()
                            onPhotoLibrary()
                        }
                    )
                    
                    CaptureOptionButton(
                        icon: "doc.viewfinder",
                        title: "Scan Document",
                        subtitle: "Scan physical documents",
                        color: .orange,
                        action: {
                            dismiss()
                            onDocumentScan()
                        }
                    )
                    
                    if clipboardMonitor.hasContent {
                        CaptureOptionButton(
                            icon: "clipboard",
                            title: "Paste from Clipboard",
                            subtitle: "Use copied content",
                            color: .purple,
                            action: {
                                dismiss()
                                onClipboardPaste()
                            }
                        )
                    }
                    
                    if screenshotDetector.hasRecentScreenshot {
                        CaptureOptionButton(
                            icon: "camera.viewfinder",
                            title: "Recent Screenshot",
                            subtitle: "Use latest screenshot",
                            color: .red,
                            action: {
                                dismiss()
                                onScreenshotCapture()
                            }
                        )
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
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
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QuickCaptureView(
        clipboardMonitor: ClipboardMonitor(),
        screenshotDetector: ScreenCaptureDetector(),
        onCameraCapture: {},
        onPhotoLibrary: {},
        onDocumentScan: {},
        onClipboardPaste: {},
        onScreenshotCapture: {}
    )
}