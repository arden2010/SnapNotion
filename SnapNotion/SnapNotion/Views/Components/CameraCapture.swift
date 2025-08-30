//
//  CameraCapture.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI
import AVFoundation
import Photos
import VisionKit

// MARK: - Camera Capture View
struct CameraCaptureView: UIViewControllerRepresentable {
    
    @Binding var isPresented: Bool
    let onImageCaptured: (Data) -> Void
    let onError: (Error) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraDevice = .rear
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCaptureView
        
        init(_ parent: CameraCaptureView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage,
               let imageData = image.jpegData(compressionQuality: 0.9) {
                parent.onImageCaptured(imageData)
            }
            
            parent.isPresented = false
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didCancel: Bool) {
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// MARK: - PhotoLibraryPicker and DocumentScannerView moved to dedicated files
// PhotoLibraryPicker is now in Views/Components/PhotoLibraryPicker.swift
// DocumentScannerView is now in Views/Components/DocumentScannerView.swift

// MARK: - ClipboardMonitor and ScreenCaptureDetector moved to Architecture/Services/
// ClipboardMonitor is now in Architecture/Services/ClipboardMonitor.swift
// ScreenCaptureDetector is now in Architecture/Services/ScreenCaptureDetector.swift