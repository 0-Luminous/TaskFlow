//
//  TaskFlowApp.swift
//  TaskFlow
//
//  Created by Yan on 13/10/24.
//

import SwiftUI

@main
struct TaskFlowApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ClockView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}