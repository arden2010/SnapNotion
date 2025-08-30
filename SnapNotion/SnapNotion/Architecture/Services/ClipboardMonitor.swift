//
//  ClipboardMonitor.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import UIKit
import SwiftUI

@MainActor
class ClipboardMonitor: ObservableObject {
    @Published var hasContent: Bool = false
    @Published var contentType: ContentType = .text
    
    func getClipboardContent() -> SharedContent? {
        let pasteboard = UIPasteboard.general
        
        if let string = pasteboard.string, !string.isEmpty {
            return SharedContent(
                type: .text,
                data: string.data(using: .utf8),
                text: string,
                url: nil,
                sourceApp: .clipboard,
                metadata: ["source": "clipboard", "timestamp": Date().timeIntervalSince1970]
            )
        }
        
        if let image = pasteboard.image {
            return SharedContent(
                type: .image,
                data: image.jpegData(compressionQuality: 0.8),
                text: nil,
                url: nil,
                sourceApp: .clipboard,
                metadata: ["source": "clipboard", "timestamp": Date().timeIntervalSince1970]
            )
        }
        
        return nil
    }
    
    func startMonitoring() {
        updateStatus()
    }
    
    func stopMonitoring() {
        // Stop monitoring
    }
    
    private func updateStatus() {
        let pasteboard = UIPasteboard.general
        hasContent = pasteboard.hasStrings || pasteboard.hasImages
        
        if pasteboard.hasImages {
            contentType = .image
        } else if pasteboard.hasStrings {
            contentType = .text
        }
    }
}