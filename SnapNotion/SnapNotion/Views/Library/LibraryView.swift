//
//  LibraryView.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI

struct LibraryView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Simple content list like Gmail
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No documents yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.filteredItems) { item in
                            ContentRowView(
                                item: item,
                                onFavoriteToggle: {
                                    viewModel.toggleFavorite(for: item)
                                },
                                onDelete: {
                                    viewModel.deleteItem(item)
                                }
                            )
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Library")
        }
        .onAppear {
            // Load content when view appears
        }
    }
}

/*
#Preview {
    LibraryView()
}
*/