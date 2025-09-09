//
//  ContentView.swift
//  SnapNotion
//
//  Created by A. C. on 8/22/25.
//

import SwiftUI
import CoreData
import UIKit
import Combine

struct ContentView: View {
    @StateObject private var screenshotManager = ScreenshotDetectionManager.shared
    @State private var selectedTab = 0
    @State private var shouldShowTasks = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: All content (inbox style)
            MainContentView(onNavigateToTasks: {
                selectedTab = 1 // Switch to Organize tab
                shouldShowTasks = true
            })
                .tabItem {
                    Image(systemName: "tray.fill")
                    Text("Inbox")
                }
                .tag(0)
            
            // Tab 2: Organized content (library, favorites, tasks)
            ContentTypesView(shouldShowTasks: $shouldShowTasks)
                .tabItem {
                    Image(systemName: "folder.fill")
                    Text("Organize")
                }
                .tag(1)
            
            // Tab 3: Knowledge connections
            KnowledgeGraphView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Insights")
                }
                .tag(2)
        }
        .screenshotProcessingBanner(
            isShowing: $screenshotManager.showProcessingBanner,
            message: screenshotManager.processingMessage
        )
        .onAppear {
            // Screenshot detection starts automatically when the manager initializes
            print("📸 SnapNotion app launched - screenshot monitoring active")
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}