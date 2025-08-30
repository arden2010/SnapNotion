//
//  NavigationController.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI
import Combine

// MARK: - Panel Types
enum NavigationPanel: CaseIterable {
    case left, main, right
    
    var offset: CGFloat {
        switch self {
        case .left: return -1
        case .main: return 0
        case .right: return 1
        }
    }
}

// MARK: - Navigation Controller
class NavigationController: ObservableObject {
    @Published var currentPanel: NavigationPanel = .main
    @Published var panelOffset: CGFloat = 0
    @Published var isDragging = false
    
    // Panel visibility states
    @Published var showLeftPanel = false
    @Published var showRightPanel = false
    
    // Gesture handling
    private let panelThreshold: CGFloat = 100
    private let snapThreshold: CGFloat = 50
    
    init() {}
    
    // MARK: - Panel Navigation
    func navigateToPanel(_ panel: NavigationPanel, animated: Bool = true) {
        withAnimation(animated ? .easeInOut(duration: 0.3) : .none) {
            currentPanel = panel
            panelOffset = panel.offset
            
            // Update panel visibility
            showLeftPanel = panel == .left
            showRightPanel = panel == .right
        }
    }
    
    func showLeftPanelAction() {
        navigateToPanel(.left)
    }
    
    func showRightPanelAction() {
        navigateToPanel(.right)
    }
    
    func returnToMainPanel() {
        navigateToPanel(.main)
    }
    
    // MARK: - Gesture Handling
    func handlePanGesture(translation: CGSize, velocity: CGSize) {
        let horizontalTranslation = translation.width
        let normalizedOffset = horizontalTranslation / UIScreen.main.bounds.width
        
        if !isDragging {
            isDragging = true
        }
        
        // Calculate new panel offset
        let baseOffset = currentPanel.offset
        let newOffset = baseOffset + normalizedOffset
        
        // Constrain offset to valid range [-1, 1]
        panelOffset = max(-1, min(1, newOffset))
    }
    
    func handlePanEnded(translation: CGSize, velocity: CGSize) {
        isDragging = false
        
        let horizontalVelocity = velocity.width
        let horizontalTranslation = translation.width
        
        // Determine target panel based on velocity and translation
        var targetPanel = currentPanel
        
        if abs(horizontalVelocity) > 500 {
            // Fast swipe - use velocity direction
            if horizontalVelocity > 0 {
                // Swipe right
                targetPanel = currentPanel == .right ? .main : 
                             currentPanel == .main ? .left : .left
            } else {
                // Swipe left
                targetPanel = currentPanel == .left ? .main : 
                             currentPanel == .main ? .right : .right
            }
        } else {
            // Slow swipe - use translation distance
            if abs(horizontalTranslation) > snapThreshold {
                if horizontalTranslation > 0 {
                    // Drag right
                    targetPanel = currentPanel == .right ? .main : 
                                 currentPanel == .main ? .left : .left
                } else {
                    // Drag left
                    targetPanel = currentPanel == .left ? .main : 
                                 currentPanel == .main ? .right : .right
                }
            }
        }
        
        navigateToPanel(targetPanel)
    }
}

// MARK: - Device Type Detection
extension NavigationController {
    var deviceType: DeviceType {
        let screen = UIScreen.main.bounds
        let width = screen.width
        
        if width < 768 {
            return .iPhone
        } else if width < 1200 {
            return .iPad
        } else {
            return .mac
        }
    }
    
    enum DeviceType {
        case iPhone, iPad, mac
        
        var usesOverlay: Bool {
            switch self {
            case .iPhone, .iPad: return true
            case .mac: return false
            }
        }
    }
}