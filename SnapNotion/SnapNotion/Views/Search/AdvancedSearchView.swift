//
//  AdvancedSearchView.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI
import Combine

struct AdvancedSearchView: View {
    @StateObject private var searchService = AdvancedSearchService.shared
    @State private var searchQuery: String = ""
    @State private var searchResults: [SearchResult] = []
    @State private var suggestions: [SearchSuggestion] = []
    @State private var selectedSearchType: SearchType = .hybrid
    @State private var isSearching: Bool = false
    @State private var showingFilters: Bool = false
    
    // Search filters
    @State private var selectedContentTypes: Set<ContentType> = []
    @State private var selectedSources: Set<String> = []
    @State private var dateRange: ClosedRange<Date>?
    @State private var minimumRelevanceScore: Double = 0.3
    
    private let searchDebounceTime: TimeInterval = 0.3
    @State private var searchCancellable: AnyCancellable?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Header
                searchHeaderView
                
                // Search Results or Suggestions
                if searchQuery.isEmpty {
                    searchSuggestionsView
                } else if isSearching {
                    searchLoadingView
                } else if searchResults.isEmpty {
                    emptySearchResultsView
                } else {
                    searchResultsView
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Filters") {
                        showingFilters.toggle()
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                SearchFiltersView(
                    selectedContentTypes: $selectedContentTypes,
                    selectedSources: $selectedSources,
                    dateRange: $dateRange,
                    minimumRelevanceScore: $minimumRelevanceScore
                )
            }
        }
        .onAppear {
            setupSearchDebouncing()
        }
    }
    
    // MARK: - Search Header
    
    private var searchHeaderView: some View {
        VStack(spacing: 12) {
            // Main Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search your knowledge base", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        performSearch()
                    }
                
                if !searchQuery.isEmpty {
                    Button(action: clearSearch) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // Search Type Picker
            Picker("Search Type", selection: $selectedSearchType) {
                Text("Smart").tag(SearchType.hybrid)
                Text("Exact").tag(SearchType.exact)
                Text("Semantic").tag(SearchType.semantic)
                Text("Fuzzy").tag(SearchType.fuzzy)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            Divider()
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Search Results
    
    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Results Header
                HStack {
                    Text("\(searchResults.count) results")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if searchService.isIndexing {
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Indexing...")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Results List
                ForEach(searchResults) { result in
                    SearchResultRowView(result: result)
                        .onTapGesture {
                            // Navigate to content detail
                        }
                    
                    if result.id != searchResults.last?.id {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
        }
    }
    
    // MARK: - Search Suggestions
    
    private var searchSuggestionsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Recent Searches
                if !searchService.searchHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Searches")
                            .claudeCodeStyle(.header3, color: .primary)
                            .padding(.horizontal)
                        
                        ForEach(searchService.searchHistory.prefix(5), id: \.self) { query in
                            SearchSuggestionRowView(
                                suggestion: SearchSuggestion(
                                    text: query,
                                    type: .recentQuery,
                                    frequency: 1
                                )
                            )
                            .onTapGesture {
                                searchQuery = query
                                performSearch()
                            }
                        }
                    }
                }
                
                // Quick Access Categories
                quickAccessCategoriesView
                
                // Search Tips
                searchTipsView
            }
            .padding(.vertical)
        }
    }
    
    private var quickAccessCategoriesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Search")
                .claudeCodeStyle(.header3, color: .primary)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickSearchCard(
                    icon: "doc.text",
                    title: "All Text",
                    subtitle: "Search documents",
                    color: .blue
                ) {
                    searchByType(.text)
                }
                
                QuickSearchCard(
                    icon: "photo",
                    title: "Images",
                    subtitle: "Visual content",
                    color: .green
                ) {
                    searchByType(.image)
                }
                
                QuickSearchCard(
                    icon: "globe",
                    title: "Web Pages",
                    subtitle: "Saved articles",
                    color: .orange
                ) {
                    searchByType(.web)
                }
                
                QuickSearchCard(
                    icon: "heart.fill",
                    title: "Favorites",
                    subtitle: "Starred items",
                    color: .red
                ) {
                    searchFavorites()
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var searchTipsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Search Tips")
                .claudeCodeStyle(.header3, color: .primary)
                .padding(.horizontal)
            
            VStack(spacing: 4) {
                SearchTipRow(tip: "Use quotes for exact phrases", example: "\"machine learning\"")
                SearchTipRow(tip: "Use - to exclude terms", example: "python -snake")
                SearchTipRow(tip: "Use OR for alternatives", example: "swift OR objective-c")
                SearchTipRow(tip: "Search by source", example: "source:safari")
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Loading and Empty States
    
    private var searchLoadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Searching...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var emptySearchResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Results Found")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Try adjusting your search terms or using different search modes")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Clear Filters") {
                clearFilters()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Search Actions
    
    private func setupSearchDebouncing() {
        // Use a simple debounced search without Combine for now
        // This can be enhanced later with proper Combine implementation
    }
    
    private func performSearch() {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        Task {
            do {
                let results = try await searchService.searchContent(
                    query: searchQuery,
                    type: selectedSearchType
                )
                
                await MainActor.run {
                    searchResults = applyFilters(to: results)
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                    // Handle error
                    reportError(error as? SnapNotionError ?? SnapNotionError.contentProcessingFailed(underlying: error.localizedDescription), in: "AdvancedSearchView", operation: "performSearch")
                }
            }
        }
    }
    
    private func updateSuggestions() {
        guard !searchQuery.isEmpty else {
            suggestions = []
            return
        }
        
        Task {
            let newSuggestions = await searchService.getSuggestions(for: searchQuery)
            await MainActor.run {
                suggestions = newSuggestions
            }
        }
    }
    
    private func clearSearch() {
        searchQuery = ""
        searchResults = []
        suggestions = []
    }
    
    private func clearFilters() {
        selectedContentTypes = []
        selectedSources = []
        dateRange = nil
        minimumRelevanceScore = 0.3
        performSearch()
    }
    
    private func searchByType(_ type: ContentType) {
        selectedContentTypes = [type]
        searchQuery = "type:\(type.rawValue)"
        performSearch()
    }
    
    private func searchFavorites() {
        searchQuery = "is:favorite"
        performSearch()
    }
    
    private func applyFilters(to results: [SearchResult]) -> [SearchResult] {
        return results.filter { result in
            // Content type filter
            if !selectedContentTypes.isEmpty {
                // This would require additional metadata in SearchResult
            }
            
            // Relevance score filter
            if result.relevanceScore < minimumRelevanceScore {
                return false
            }
            
            // Date range filter
            // This would require date metadata in SearchResult
            
            return true
        }
    }
}

// MARK: - Helper Views

struct SearchResultRowView: View {
    let result: SearchResult
    
    var body: some View {
        HStack(spacing: 16) {
            // Content type icon
            Image(systemName: contentTypeIcon)
                .font(.title2)
                .foregroundColor(contentTypeColor)
                .frame(width: 32)
            
            // Content info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(result.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    // Relevance score
                    Text("\(Int(result.relevanceScore * 100))%")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.phoenixOrange.opacity(0.2))
                        .foregroundColor(.phoenixOrange)
                        .cornerRadius(4)
                }
                
                Text(result.preview)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    matchTypeChip
                    
                    if let similarity = result.semanticSimilarity {
                        Text("Semantic: \(Int(similarity * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .contentShape(Rectangle())
    }
    
    private var contentTypeIcon: String {
        // This would map based on content type
        return "doc.text"
    }
    
    private var contentTypeColor: Color {
        // This would map based on content type
        return .blue
    }
    
    private var matchTypeChip: some View {
        Group {
            switch result.matchType {
            case .exactMatch:
                Text("Exact")
                    .foregroundColor(.green)
            case .fuzzyMatch:
                Text("Fuzzy")
                    .foregroundColor(.orange)
            case .semanticMatch:
                Text("Semantic")
                    .foregroundColor(.purple)
            case .hybridMatch:
                Text("Smart")
                    .foregroundColor(.blue)
            }
        }
        .font(.caption2)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color(.systemGray5))
        .cornerRadius(4)
    }
}

struct SearchSuggestionRowView: View {
    let suggestion: SearchSuggestion
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: suggestionIcon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(suggestion.text)
                .font(.body)
            
            Spacer()
            
            if suggestion.type == .recentQuery {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    private var suggestionIcon: String {
        switch suggestion.type {
        case .recentQuery: return "clock.arrow.circlepath"
        case .popularContent: return "flame"
        case .semanticSimilar: return "brain"
        case .autoComplete: return "magnifyingglass"
        }
    }
}

struct QuickSearchCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SearchTipRow: View {
    let tip: String
    let example: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(tip)
                    .font(.caption)
                    .foregroundColor(.primary)
                
                Text(example)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray6))
                    .cornerRadius(4)
            }
            
            Spacer()
        }
    }
}

#Preview {
    AdvancedSearchView()
}