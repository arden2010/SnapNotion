//
//  TextEditorSheet.swift
//  SnapNotion
//
//  Text editor modal for manual text content creation
//  Created by A. C. on 9/7/25.
//

import SwiftUI

struct TextEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var text: String
    let onSave: (String) -> Void
    
    @State private var localText: String = ""
    @FocusState private var isTextEditorFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Text Editor
                TextEditor(text: $localText)
                    .focused($isTextEditorFocused)
                    .font(.body)
                    .padding()
                    .background(Color(.systemBackground))
                
                Spacer()
            }
            .navigationTitle("New Text Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(localText)
                        dismiss()
                    }
                    .disabled(localText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            localText = text
            isTextEditorFocused = true
        }
    }
}

#Preview {
    TextEditorSheet(text: .constant("")) { _ in }
}