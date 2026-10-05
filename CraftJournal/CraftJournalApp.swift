//
//  CraftJournalApp.swift
//  CraftJournal
//
//  Created by iMac23 on 10/5/26.
//

import SwiftUI
import CoreData

@main
struct CraftJournalApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
