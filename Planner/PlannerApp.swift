//
//  PlannerApp.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftUI
import SwiftData

@main
struct PlannerApp: App {
    let todaystampManager = TodaystampManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(.blue)
                .environmentObject(todaystampManager)
        }
        .modelContainer(for: PlannerEvent.self)
    }
}
