//
//  FavoritesView.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading favorites...")
                    Spacer()
                } else if favoriteItems.isEmpty {
                    FavoritesEmptyState()
                } else {
                    List(favoriteItems) { item in
                        FavoriteItemRow(item: item) {
                            viewModel.toggleFavorite(for: item)
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
        }
        .onAppear {
            viewModel.selectedFilter = .favorites
        }
    }
    
    private var favoriteItems: [ContentItem] {
        viewModel.contentItems.filter { $0.isFavorite }
    }
}

struct FavoritesEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 64))
                .foregroundColor(.red)
            
            Text("No Favorites Yet")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Tap the heart icon on any content to add it to your favorites")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Browse Library") {
                // TODO: Navigate to library tab
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FavoriteItemRow: View {
    let item: ContentItem
    let onToggleFavorite: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(item.preview)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(item.source)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(item.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: onToggleFavorite) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.title2)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    FavoritesView()
}