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
    var body: some View {
        TabView {
            // Tab 1: All content (inbox style)
            MainContentView()
                .tabItem {
                    Image(systemName: "tray.fill")
                    Text("Inbox")
                }
            
            // Tab 2: Organized content (library, favorites, tasks)
            ContentTypesView()
                .tabItem {
                    Image(systemName: "folder.fill")
                    Text("Organize")
                }
            
            // Tab 3: Knowledge connections
            KnowledgeGraphView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Insights")
                }
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}