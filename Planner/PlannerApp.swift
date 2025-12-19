//
//  PlannerApp.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftData
import SwiftUI

enum AppAccent: String, CaseIterable, Identifiable {
    case blue
    case green
    case red
    case purple

    var id: String { rawValue }
}

@main
struct PlannerApp: App {
    let todaystampManager = TodaystampManager()

    @StateObject private var calendarStore = CalendarEventStore()
    
    @AppStorage("themeColor") var themeColor: ColorOption = ColorOption.green

    var body: some Scene {
        WindowGroup {
            ContentView()
                .accentColor(themeColor.swiftUIColor)
                .environmentObject(todaystampManager)
                .environmentObject(calendarStore)
                .onAppear {
                    calendarStore.requestAccessAndLoadIfNeeded()
                }
        }
        .modelContainer(for: [PlannerEvent.self, ChecklistItem.self])
    }
}
