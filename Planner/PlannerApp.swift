//
//  PlannerApp.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftData
import SwiftUI

@main
struct PlannerApp: App {
    
    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue
    
    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme
        .system

    @State private var navigator = NavigationManager()
    let weatherStore = WeatherStore.shared
    let todaystampWatcher = TodaystampWatcher.shared
    let calendarStore = CalendarStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appColorScheme.colorScheme)
                .accentColor(accentColor.swiftUIColor)
                .environmentObject(todaystampWatcher)
                .environmentObject(weatherStore)
                .environmentObject(calendarStore)
                .environmentObject(navigator)
        }
        .modelContainer(for: [
            Planner.self, ChecklistItem.self, CalendarSettings.self, PlannerSettings.self
        ])
    }
}
