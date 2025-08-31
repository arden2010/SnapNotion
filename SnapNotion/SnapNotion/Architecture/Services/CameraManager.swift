//
//  CameraManager.swift
//  SnapNotion
//
//  Created by A. C. on 8/31/25.
//

import Foundation
import AVFoundation
import UIKit

@MainActor
class CameraManager: ObservableObject {
    
    static let shared = CameraManager()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    
    init() {
        checkCameraPermission()
    }
    
    func checkCameraPermission() {
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        isAuthorized = authorizationStatus == .authorized
    }
    
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
                self.isAuthorized = granted
                completion(granted)
            }
        }
    }
}