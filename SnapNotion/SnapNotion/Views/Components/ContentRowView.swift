//
//  ContentRowView.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI

struct ContentRowView: View {
    let item: ContentItem
    let onFavoriteToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Content type icon
            Image(systemName: item.typeIcon)
                .font(.title2)
                .foregroundColor(item.typeColor)
                .frame(width: 32)
            
            // Content info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(item.preview)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(item.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(item.source)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Actions
            VStack {
                Button(action: onFavoriteToggle) {
                    Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(item.isFavorite ? .red : .gray)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
            
            Button(action: onFavoriteToggle) {
                Label(item.isFavorite ? "Unfavorite" : "Favorite", systemImage: item.isFavorite ? "heart.slash" : "heart")
            }
            .tint(.orange)
        }
    }
}

extension ContentItem {
    var typeIcon: String {
        switch type {
        case .text: return "doc.text"
        case .image: return "photo"
        case .web: return "globe"
        case .pdf: return "doc.richtext"
        case .mixed: return "doc.on.doc"
        }
    }
    
    var typeColor: Color {
        switch type {
        case .text: return .blue
        case .image: return .green
        case .web: return .orange
        case .pdf: return .red
        case .mixed: return .purple
        }
    }
}