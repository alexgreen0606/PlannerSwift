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
    @AppStorage("themeColor") var themeColor: ThemeColor =
        ThemeColor.blue

    let weatherStore = WeatherStore.shared
    let todaystampWatcher = TodaystampWatcher.shared
    let calendarStore = CalendarStore.shared

    @StateObject private var navigationManager = NavigationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .accentColor(themeColor.swiftUIColor)
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
