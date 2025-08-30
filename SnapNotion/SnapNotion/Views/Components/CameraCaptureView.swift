//
//  CameraCaptureView.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI
import UIKit

struct CameraCaptureView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onImageCaptured: (Data) -> Void
    let onError: (Error) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
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
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage,
               let imageData = editedImage.jpegData(compressionQuality: 0.8) {
                parent.onImageCaptured(imageData)
            } else {
                parent.onError(NSError(domain: "CameraCapture", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to capture image"]))
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}