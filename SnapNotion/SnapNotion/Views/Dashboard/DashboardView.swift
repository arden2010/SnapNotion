//
//  DashboardView.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    @State private var showingAddSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Content List - Gmail style
                    if viewModel.isLoading {
                        ProgressView("Loading...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.filteredItems.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "tray")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("No content yet")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            
                            Text("Content you capture will appear here")
                                .font(.body)
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
                .navigationTitle("All Content")
                
                // Floating Action Button (FAB) - Gmail style
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingAddSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .frame(width: 56, height: 56)
                        .background(Color.phoenixOrange)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddContentSheet()
        }
        .onAppear {
            // Load content when view appears
        }
    }
}

#Preview {
    DashboardView()
}