//
//  SearchFiltersView.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI

struct SearchFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedContentTypes: Set<SnapNotion.ContentType>
    @Binding var selectedSources: Set<String>
    @Binding var dateRange: ClosedRange<Date>?
    @Binding var minimumRelevanceScore: Double
    
    @State private var showingDatePicker = false
    @State private var startDate = Date().addingTimeInterval(-30*24*3600) // 30 days ago
    @State private var endDate = Date()
    
    private let availableSources = ["safari", "clipboard", "camera", "photos", "other"]
    private let allContentTypes: [SnapNotion.ContentType] = [.text, .image, .web, .pdf, .mixed]
    
    var body: some View {
        NavigationView {
            Form {
                // Content Type Filter
                contentTypeSection
                
                // Source Filter
                sourceFilterSection
                
                // Date Range Filter
                dateRangeSection
                
                // Relevance Score Filter
                relevanceScoreSection
                
                // Reset Section
                resetSection
            }
            .navigationTitle("Search Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset All") {
                        resetAllFilters()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Content Type Section
    
    private var contentTypeSection: some View {
        Section("Content Type") {
            ForEach(allContentTypes, id: \.self) { contentType in
                HStack {
                    Image(systemName: iconFor(contentType: contentType))
                        .foregroundColor(colorFor(contentType: contentType))
                        .frame(width: 24)
                    
                    Text(contentType.displayName)
                        .font(.body)
                    
                    Spacer()
                    
                    if selectedContentTypes.contains(contentType) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleContentType(contentType)
                }
            }
        }
    }
    
    // MARK: - Source Filter Section
    
    private var sourceFilterSection: some View {
        Section("Source Application") {
            ForEach(availableSources, id: \.self) { source in
                HStack {
                    Image(systemName: iconFor(source: source))
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    
                    Text(source.capitalized)
                        .font(.body)
                    
                    Spacer()
                    
                    if selectedSources.contains(source) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleSource(source)
                }
            }
        }
    }
    
    // MARK: - Date Range Section
    
    private var dateRangeSection: some View {
        Section("Date Range") {
            HStack {
                Text("Filter by date")
                Spacer()
                Toggle("", isOn: .constant(dateRange != nil))
                    .onChange(of: dateRange != nil) { enabled in
                        if enabled {
                            dateRange = startDate...endDate
                        } else {
                            dateRange = nil
                        }
                    }
            }
            
            if dateRange != nil {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("From:")
                            .foregroundColor(.secondary)
                        Spacer()
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("To:")
                            .foregroundColor(.secondary)
                        Spacer()
                        DatePicker("", selection: $endDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                }
                .onChange(of: startDate) { _ in updateDateRange() }
                .onChange(of: endDate) { _ in updateDateRange() }
            }
        }
    }
    
    // MARK: - Relevance Score Section
    
    private var relevanceScoreSection: some View {
        Section("Minimum Relevance") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Minimum Score: \(Int(minimumRelevanceScore * 100))%")
                        .font(.body)
                    
                    Spacer()
                    
                    Text("More Results")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $minimumRelevanceScore, in: 0.0...1.0, step: 0.05)
                    .tint(.phoenixOrange)
                
                HStack {
                    Text("0%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("100%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("Higher scores show more relevant results but may miss some matches")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Reset Section
    
    private var resetSection: some View {
        Section {
            Button("Reset All Filters") {
                resetAllFilters()
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Helper Methods
    
    private func toggleContentType(_ contentType: ContentType) {
        if selectedContentTypes.contains(contentType) {
            selectedContentTypes.remove(contentType)
        } else {
            selectedContentTypes.insert(contentType)
        }
    }
    
    private func toggleSource(_ source: String) {
        if selectedSources.contains(source) {
            selectedSources.remove(source)
        } else {
            selectedSources.insert(source)
        }
    }
    
    private func updateDateRange() {
        if startDate <= endDate {
            dateRange = startDate...endDate
        }
    }
    
    private func resetAllFilters() {
        selectedContentTypes.removeAll()
        selectedSources.removeAll()
        dateRange = nil
        minimumRelevanceScore = 0.3
    }
    
    private func iconFor(contentType: ContentType) -> String {
        switch contentType {
        case .text: return "doc.text"
        case .image: return "photo"
        case .web: return "globe"
        case .pdf: return "doc.richtext"
        case .mixed: return "doc.on.doc"
        }
    }
    
    private func colorFor(contentType: ContentType) -> Color {
        switch contentType {
        case .text: return .blue
        case .image: return .green
        case .web: return .orange
        case .pdf: return .red
        case .mixed: return .purple
        }
    }
    
    private func iconFor(source: String) -> String {
        switch source.lowercased() {
        case "safari": return "safari"
        case "clipboard": return "clipboard"
        case "camera": return "camera"
        case "photos": return "photo.on.rectangle"
        default: return "app"
        }
    }
}

// MARK: - ContentType displayName extension is in SimpleModels.swift

#Preview {
    SearchFiltersView(
        selectedContentTypes: Binding.constant(Set<SnapNotion.ContentType>()),
        selectedSources: Binding.constant(Set<String>()),
        dateRange: Binding.constant(nil as ClosedRange<Date>?),
        minimumRelevanceScore: Binding.constant(0.3)
    )
}