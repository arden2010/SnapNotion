//
//  DocumentScannerView.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI
import VisionKit

@available(iOS 13.0, *)
struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onDocumentScanned: ([Data]) -> Void
    let onError: (Error) -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView
        
        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var scannedData: [Data] = []
            
            for pageIndex in 0..<scan.pageCount {
                let scannedImage = scan.imageOfPage(at: pageIndex)
                if let imageData = scannedImage.jpegData(compressionQuality: 0.8) {
                    scannedData.append(imageData)
                }
            }
            
            if !scannedData.isEmpty {
                parent.onDocumentScanned(scannedData)
            } else {
                parent.onError(NSError(domain: "DocumentScanner", code: -1, userInfo: [NSLocalizedDescriptionKey: "No pages were scanned"]))
            }
            
            parent.isPresented = false
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.onError(error)
            parent.isPresented = false
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.isPresented = false
        }
    }
}