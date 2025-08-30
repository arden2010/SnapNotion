//
//  ClaudeCodeTypography.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI

// MARK: - Claude Code Typography System
struct ClaudeCodeTypography {
    
    // MARK: - Font Styles
    enum FontStyle: CaseIterable {
        case header1
        case header2
        case header3
        case body
        case bodyMedium
        case caption
        case code
        case monospaceTitle
        
        var font: Font {
            switch self {
            case .header1:
                return .custom("SF Mono", size: 28, relativeTo: .largeTitle).weight(.bold)
            case .header2:
                return .custom("SF Mono", size: 22, relativeTo: .title).weight(.semibold)
            case .header3:
                return .custom("SF Mono", size: 18, relativeTo: .title2).weight(.medium)
            case .body:
                return .system(size: 16, weight: .regular, design: .default)
            case .bodyMedium:
                return .system(size: 16, weight: .medium, design: .default)
            case .caption:
                return .system(size: 14, weight: .regular, design: .default)
            case .code:
                return .custom("SF Mono", size: 14, relativeTo: .body)
            case .monospaceTitle:
                return .custom("SF Mono", size: 20, relativeTo: .title3).weight(.semibold)
            }
        }
        
        var lineSpacing: CGFloat {
            switch self {
            case .header1, .header2, .header3, .monospaceTitle:
                return 2
            case .body, .bodyMedium:
                return 4
            case .caption, .code:
                return 2
            }
        }
    }
    
    // MARK: - Color Palette
    enum TextColor: CaseIterable {
        case primary
        case secondary
        case tertiary
        case accent
        case success
        case warning
        case error
        case code
        
        var color: Color {
            switch self {
            case .primary:
                return Color(.label)
            case .secondary:
                return Color(.secondaryLabel)
            case .tertiary:
                return Color(.tertiaryLabel)
            case .accent:
                return .blue
            case .success:
                return .green
            case .warning:
                return .orange
            case .error:
                return .red
            case .code:
                return Color(.systemPurple)
            }
        }
    }
}

// MARK: - Typography Extensions
extension Text {
    func claudeCodeStyle(_ style: ClaudeCodeTypography.FontStyle, color: ClaudeCodeTypography.TextColor = .primary) -> some View {
        self
            .font(style.font)
            .foregroundColor(color.color)
            .lineSpacing(style.lineSpacing)
    }
}

// MARK: - Typography Preview Components
struct TypographyPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Headers (Monospace)")
                        .claudeCodeStyle(.bodyMedium, color: .secondary)
                    
                    Text("Header 1: Claude Code")
                        .claudeCodeStyle(.header1)
                    
                    Text("Header 2: SnapNotion")
                        .claudeCodeStyle(.header2)
                    
                    Text("Header 3: Typography System")
                        .claudeCodeStyle(.header3)
                    
                    Text("Monospace Title: Code Editor")
                        .claudeCodeStyle(.monospaceTitle, color: .accent)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Body Text")
                        .claudeCodeStyle(.bodyMedium, color: .secondary)
                    
                    Text("Body: This is the standard body text used throughout the application for readable content.")
                        .claudeCodeStyle(.body)
                    
                    Text("Body Medium: This is medium weight body text for emphasis.")
                        .claudeCodeStyle(.bodyMedium)
                    
                    Text("Caption: Additional information or metadata")
                        .claudeCodeStyle(.caption, color: .secondary)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Code & Technical")
                        .claudeCodeStyle(.bodyMedium, color: .secondary)
                    
                    Text("func processImage() -> UIImage?")
                        .claudeCodeStyle(.code, color: .code)
                    
                    Text("Status: Processing...")
                        .claudeCodeStyle(.caption, color: .warning)
                    
                    Text("Error: File not found")
                        .claudeCodeStyle(.caption, color: .error)
                    
                    Text("Success: Content captured")
                        .claudeCodeStyle(.caption, color: .success)
                }
            }
            .padding()
        }
        .navigationTitle("Typography")
    }
}

#Preview {
    NavigationView {
        TypographyPreview()
    }
}