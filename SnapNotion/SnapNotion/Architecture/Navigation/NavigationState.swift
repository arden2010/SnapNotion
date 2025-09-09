//
//  NavigationState.swift
//  SnapNotion
//
//  Navigation state manager for cross-tab navigation and task routing
//  Created by A. C. on 9/9/25.
//

import Foundation
import SwiftUI

class NavigationState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var selectedTasksSection: Bool = false
    @Published var selectedTaskId: UUID?
    
    func navigateToTasks() {
        selectedTab = 1 // Navigate to Organize tab
        selectedTasksSection = true // Show tasks section
    }
    
    func navigateToTasksWithTask(_ taskId: UUID) {
        selectedTab = 1 // Navigate to Organize tab
        selectedTasksSection = true // Show tasks section
        selectedTaskId = taskId // Highlight specific task
    }
    
    func resetNavigation() {
        selectedTasksSection = false
        selectedTaskId = nil
    }
}