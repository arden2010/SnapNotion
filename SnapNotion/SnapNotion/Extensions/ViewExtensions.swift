//
//  ViewExtensions.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI

// MARK: - Claude Code Style Extension
extension View {
    func claudeCodeStyle(_ style: ClaudeCodeTextStyle, color: Color = .primary) -> some View {
        modifier(ClaudeCodeStyleModifier(style: style, color: color))
    }
}

// MARK: - Claude Code Text Styles
enum ClaudeCodeTextStyle {
    case header1
    case header2
    case header3
    case body
    case bodyMedium
    case caption
    case caption2
    case small
}

// MARK: - Claude Code Style Modifier
struct ClaudeCodeStyleModifier: ViewModifier {
    let style: ClaudeCodeTextStyle
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .font(fontForStyle(style))
            .foregroundColor(color)
    }
    
    private func fontForStyle(_ style: ClaudeCodeTextStyle) -> Font {
        switch style {
        case .header1:
            return .largeTitle
        case .header2:
            return .title
        case .header3:
            return .title2
        case .body:
            return .body
        case .bodyMedium:
            return .system(size: 17, weight: .medium)
        case .caption:
            return .caption
        case .caption2:
            return .caption2
        case .small:
            return .footnote
        }
    }
}

// MARK: - Color Extensions
extension Color {
    static let error = Color.red
    static let accent = Color.accentColor
}