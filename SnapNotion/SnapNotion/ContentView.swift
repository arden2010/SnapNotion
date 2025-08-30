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
            // Tab 1: Main content page (all content types)
            MainContentView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            
            // Tab 2: Content types (library, favorites, tasks)
            ContentTypesView()
                .tabItem {
                    Image(systemName: "folder")
                    Text("Types")
                }
            
            // Tab 3: Knowledge graph
            KnowledgeGraphView()
                .tabItem {
                    Image(systemName: "network")
                    Text("Graph")
                }
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}