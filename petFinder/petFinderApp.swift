//
//  petFinderApp.swift
//  petFinder
//
//  Created by user272268 on 4/11/25.
//

import SwiftUI

@main
struct petFinderApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
