//
//  ShareViewController.swift
//  SnapNotionShareExtension
//
//  Created by A. C. on 8/30/25.
//

import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

// MARK: - Share Extension View Controller
class ShareViewController: SLComposeServiceViewController {
    
    // MARK: - Properties
    private var sharedContent: SharedContent?
    private lazy var contentProcessor: ShareExtensionContentProcessor? = {
        return try? ShareExtensionContentProcessor()
    }()
    
    // MARK: - Lifecycle
    override func isContentValid() -> Bool {
        // Validate content before allowing sharing
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            return false
        }
        
        return extractSharedContent(from: extensionItems) != nil
    }
    
    override func didSelectPost() {
        guard let content = sharedContent else {
            completeRequest(returningItems: nil, completionHandler: nil)
            return
        }
        
        guard let processor = contentProcessor else {
            showErrorMessage(ShareExtensionError.appGroupContainerNotAccessible)
            completeRequest(returningItems: nil, completionHandler: nil)
            return
        }
        
        // Add user's comment if provided
        let userText = contentText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let finalContent = content.withAdditionalText(userText)
        
        // Process and save content
        processor.processSharedContent(finalContent) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Show success message
                    self?.showSuccessMessage()
                case .failure(let error):
                    // Show error message
                    self?.showErrorMessage(error)
                }
                
                // Complete the extension
                self?.completeRequest(returningItems: nil, completionHandler: nil)
            }
        }
    }
    
    override func configurationItems() -> [Any]! {
        // Add configuration options if needed
        guard let sourceAppItem = SLComposeSheetConfigurationItem() else { return [] }
        
        sourceAppItem.title = "Source App"
        sourceAppItem.value = detectSourceApp()
        sourceAppItem.tapHandler = {
            // Handle source app selection if needed
        }
        
        return [sourceAppItem]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Customize appearance
        setupUI()
        
        // Extract shared content
        if let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] {
            sharedContent = extractSharedContent(from: extensionItems)
        }
        
        // Set placeholder text
        placeholder = "Add a note about this content..."
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        // Customize the share sheet appearance
        navigationController?.navigationBar.tintColor = .systemBlue
        view.backgroundColor = .systemBackground
    }
    
    private func extractSharedContent(from extensionItems: [NSExtensionItem]) -> SharedContent? {
        for item in extensionItems {
            if let attachments = item.attachments {
                for provider in attachments {
                    // Handle different content types
                    if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                        return extractImageContent(from: provider, item: item)
                    } else if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                        return extractTextContent(from: provider, item: item)
                    } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                        return extractURLContent(from: provider, item: item)
                    } else if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                        return extractPDFContent(from: provider, item: item)
                    }
                }
            }
        }
        return nil
    }
    
    private func extractImageContent(from provider: NSItemProvider, item: NSExtensionItem) -> SharedContent? {
        var imageData: Data?
        let semaphore = DispatchSemaphore(value: 0)
        
        provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { (data, error) in
            if let url = data as? URL {
                imageData = try? Data(contentsOf: url)
            } else if let image = data as? UIImage {
                imageData = image.jpegData(compressionQuality: 0.8)
            } else if let data = data as? Data {
                imageData = data
            }
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .now() + 5.0)
        
        guard let data = imageData else { return nil }
        
        return SharedContent(
            type: .image,
            data: data,
            text: item.attributedTitle?.string,
            url: nil,
            sourceApp: detectSourceApp(),
            metadata: extractMetadata(from: item)
        )
    }
    
    private func extractTextContent(from provider: NSItemProvider, item: NSExtensionItem) -> SharedContent? {
        var textContent: String?
        let semaphore = DispatchSemaphore(value: 0)
        
        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { (data, error) in
            if let text = data as? String {
                textContent = text
            } else if let attributedText = data as? NSAttributedString {
                textContent = attributedText.string
            }
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .now() + 5.0)
        
        guard let text = textContent else { return nil }
        
        return SharedContent(
            type: .text,
            data: nil,
            text: text,
            url: nil,
            sourceApp: detectSourceApp(),
            metadata: extractMetadata(from: item)
        )
    }
    
    private func extractURLContent(from provider: NSItemProvider, item: NSExtensionItem) -> SharedContent? {
        var urlContent: URL?
        let semaphore = DispatchSemaphore(value: 0)
        
        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { (data, error) in
            if let url = data as? URL {
                urlContent = url
            } else if let string = data as? String, let url = URL(string: string) {
                urlContent = url
            }
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .now() + 5.0)
        
        guard let url = urlContent else { return nil }
        
        return SharedContent(
            type: .web,
            data: nil,
            text: item.attributedTitle?.string,
            url: url,
            sourceApp: detectSourceApp(),
            metadata: extractMetadata(from: item)
        )
    }
    
    private func extractPDFContent(from provider: NSItemProvider, item: NSExtensionItem) -> SharedContent? {
        var pdfData: Data?
        let semaphore = DispatchSemaphore(value: 0)
        
        provider.loadItem(forTypeIdentifier: UTType.pdf.identifier, options: nil) { (data, error) in
            if let url = data as? URL {
                pdfData = try? Data(contentsOf: url)
            } else if let data = data as? Data {
                pdfData = data
            }
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .now() + 5.0)
        
        guard let data = pdfData else { return nil }
        
        return SharedContent(
            type: .pdf,
            data: data,
            text: item.attributedTitle?.string,
            url: nil,
            sourceApp: detectSourceApp(),
            metadata: extractMetadata(from: item)
        )
    }
    
    private func detectSourceApp() -> AppSource {
        // Try to detect the source app from the extension context
        guard let host = extensionContext?.inputItems.first?.attachments?.first?.registeredTypeIdentifiers.first else {
            return .unknown
        }
        
        // Map common bundle identifiers to app sources
        if host.contains("whatsapp") {
            return .whatsapp
        } else if host.contains("tiktok") {
            return .tiktok
        } else if host.contains("wechat") {
            return .wechat
        } else if host.contains("instagram") {
            return .instagram
        } else if host.contains("twitter") {
            return .twitter
        } else if host.contains("safari") {
            return .safari
        } else if host.contains("photos") {
            return .photos
        } else {
            return .unknown
        }
    }
    
    private func extractMetadata(from item: NSExtensionItem) -> [String: Any] {
        var metadata: [String: Any] = [:]
        
        metadata["title"] = item.attributedTitle?.string
        metadata["contentText"] = item.attributedContentText?.string
        metadata["timestamp"] = Date()
        
        return metadata
    }
    
    private func showSuccessMessage() {
        let alert = UIAlertController(
            title: "Success",
            message: "Content has been saved to SnapNotion",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showErrorMessage(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: "Failed to save content: \(error.localizedDescription)",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - SharedContent Extension
extension SharedContent {
    func withAdditionalText(_ text: String) -> SharedContent {
        let combinedText = [self.text, text].compactMap { $0?.isEmpty == false ? $0 : nil }.joined(separator: "\n\n")
        
        return SharedContent(
            type: self.type,
            data: self.data,
            text: combinedText.isEmpty ? nil : combinedText,
            url: self.url,
            sourceApp: self.sourceApp,
            metadata: self.metadata
        )
    }
}