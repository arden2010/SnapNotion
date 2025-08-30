//
//  StyleExtensions.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI

// MARK: - Text Style Extension
extension Text {
    func claudeCodeStyle(_ style: ClaudeCodeTextStyle, color: Color = .primary) -> some View {
        self.modifier(ClaudeCodeTextStyleModifier(style: style, color: color))
    }
}

enum ClaudeCodeTextStyle {
    case header1
    case header2
    case header3
    case body
    case caption
    case caption2
}

struct ClaudeCodeTextStyleModifier: ViewModifier {
    let style: ClaudeCodeTextStyle
    let color: Color
    
    func body(content: Content) -> some View {
        switch style {
        case .header1:
            content
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(color)
        case .header2:
            content
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(color)
        case .header3:
            content
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(color)
        case .body:
            content
                .font(.body)
                .foregroundColor(color)
        case .caption:
            content
                .font(.caption)
                .foregroundColor(color)
        case .caption2:
            content
                .font(.caption2)
                .foregroundColor(color)
        }
    }
}