//
//  SnapNotionApp.swift
//  SnapNotion
//
//  Created by A. C. on 8/22/25.
//

import SwiftUI

@main
struct SnapNotionApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
