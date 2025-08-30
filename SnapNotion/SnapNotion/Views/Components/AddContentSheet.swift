//
//  AddContentSheet.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI

struct AddContentSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Add Content")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Choose how you'd like to capture content")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical)
                    
                    // Add Content Options
                    VStack(spacing: 12) {
                        AddContentOption(
                            icon: "camera",
                            title: "Camera",
                            subtitle: "Take a photo or scan document",
                            color: .blue
                        ) {
                            // TODO: Open camera
                            dismiss()
                        }
                        
                        AddContentOption(
                            icon: "photo",
                            title: "Photo Library",
                            subtitle: "Choose from your photos",
                            color: .green
                        ) {
                            // TODO: Open photo library
                            dismiss()
                        }
                        
                        AddContentOption(
                            icon: "doc.text",
                            title: "Text Note",
                            subtitle: "Create a new text note",
                            color: .orange
                        ) {
                            // TODO: Create text note
                            dismiss()
                        }
                        
                        AddContentOption(
                            icon: "link",
                            title: "Web Link",
                            subtitle: "Save a website or URL",
                            color: .purple
                        ) {
                            // TODO: Add web link
                            dismiss()
                        }
                        
                        AddContentOption(
                            icon: "doc.on.clipboard",
                            title: "From Clipboard",
                            subtitle: "Paste clipboard content",
                            color: .red
                        ) {
                            // TODO: Add from clipboard
                            dismiss()
                        }
                        
                        AddContentOption(
                            icon: "square.and.arrow.down",
                            title: "Import File",
                            subtitle: "Import PDF, document, or image",
                            color: .indigo
                        ) {
                            // TODO: Import file
                            dismiss()
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AddContentOption: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddContentSheet()
}