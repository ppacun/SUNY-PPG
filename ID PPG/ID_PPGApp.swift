//
//  ID_PPGApp.swift
//  ID PPG
//
//  Created by Paul Pacun on 9/14/26.
//

import SwiftUI
import CoreData

@main
struct ID_PPGApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
