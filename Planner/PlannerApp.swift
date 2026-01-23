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

    let weatherStore = WeatherStore.shared
    let todaystampWatcher = TodaystampWatcher.shared
    let calendarStore = CalendarStore.shared

    @StateObject private var navigationManager = NavigationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appColorScheme.colorScheme)
                .accentColor(accentColor.swiftUIColor)
                .environmentObject(todaystampWatcher)
                .environmentObject(weatherStore)
                .environmentObject(calendarStore)
                .environmentObject(navigationManager)
                .task {
                    Task {
                        await weatherStore.loadWeather()
                    }
                }
        }
        .modelContainer(for: [
            Planner.self, ChecklistItem.self, CalendarSettings.self,
        ])
    }
}
