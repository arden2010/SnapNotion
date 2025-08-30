//
//  ClipboardMonitor.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import UIKit
import SwiftUI

// MARK: - Clipboard Monitor
@MainActor
class ClipboardMonitor: ObservableObject {
    
    @Published var hasImageContent = false
    @Published var hasTextContent = false
    @Published var hasURLContent = false
    
    var hasContent: Bool {
        return hasImageContent || hasTextContent || hasURLContent
    }
    
    private var lastChangeCount: Int = 0
    private var timer: Timer?
    
    init() {
        startMonitoring()
    }
    
    deinit {
        Task { @MainActor in
            stopMonitoring()
        }
    }
    
    func startMonitoring() {
        lastChangeCount = UIPasteboard.general.changeCount
        updateContentStatus()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.checkForChanges()
            }
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    func getClipboardContent() -> SharedContent? {
        let pasteboard = UIPasteboard.general
        
        // Check for image
        if pasteboard.hasImages, let image = pasteboard.image,
           let imageData = image.jpegData(compressionQuality: 0.9) {
            return SharedContent(
                type: .image,
                data: imageData,
                text: nil,
                url: nil,
                sourceApp: .clipboard,
                metadata: ["source": "clipboard", "type": "image"]
            )
        }
        
        // Check for URL
        if pasteboard.hasURLs, let url = pasteboard.url {
            return SharedContent(
                type: .web,
                data: nil,
                text: pasteboard.string,
                url: url,
                sourceApp: .clipboard,
                metadata: ["source": "clipboard", "type": "url"]
            )
        }
        
        // Check for text
        if pasteboard.hasStrings, let string = pasteboard.string {
            return SharedContent(
                type: .text,
                data: nil,
                text: string,
                url: nil,
                sourceApp: .clipboard,
                metadata: ["source": "clipboard", "type": "text"]
            )
        }
        
        return nil
    }
    
    private func checkForChanges() {
        let currentChangeCount = UIPasteboard.general.changeCount
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount
            updateContentStatus()
        }
    }
    
    private func updateContentStatus() {
        let pasteboard = UIPasteboard.general
        
        hasImageContent = pasteboard.hasImages
        hasTextContent = pasteboard.hasStrings
        hasURLContent = pasteboard.hasURLs
    }
}