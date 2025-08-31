//
//  SmartSuggestionsView.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI

// MARK: - Smart Suggestions View
struct SmartSuggestionsView: View {
    @ObservedObject var clipboardMonitor: ClipboardMonitor
    @ObservedObject var screenshotDetector: ScreenshotDetectionManager
    
    let onClipboardPaste: () -> Void
    let onScreenshotCapture: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("智能建议")
                .claudeCodeStyle(.header3, color: .accent)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Recent screenshot suggestion
                    if screenshotDetector.lastScreenshotImage != nil {
                        SmartSuggestionCard(
                            icon: "camera.viewfinder",
                            title: "最近截图",
                            subtitle: "处理刚刚的截图",
                            color: .blue,
                            badge: "NEW"
                        ) {
                            onScreenshotCapture()
                        }
                    }
                    
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Smart Suggestion Card
struct SmartSuggestionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let badge: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                    
                    // Badge overlay
                    if let badge = badge {
                        VStack {
                            HStack {
                                Spacer()
                                Text(badge)
                                    .claudeCodeStyle(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .cornerRadius(8)
                                    .offset(x: 10, y: -10)
                            }
                            Spacer()
                        }
                    }
                }
                
                VStack(spacing: 2) {
                    Text(title)
                        .claudeCodeStyle(.bodyMedium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .claudeCodeStyle(.caption, color: .secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(width: 120)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    SmartSuggestionsView(
        clipboardMonitor: ClipboardMonitor(),
        screenshotDetector: ScreenshotDetectionManager.shared,
        onClipboardPaste: { },
        onScreenshotCapture: { }
    )
}