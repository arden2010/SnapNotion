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
        ThreePanelNavigationView()
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}