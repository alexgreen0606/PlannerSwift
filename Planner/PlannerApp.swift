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
    @AppStorage("lastCleanedDatestamp") var lastCleanedDatestamp: String =
        ""

    let weatherStore = WeatherStore.shared
    let todaystampWatcher = TodaystampWatcher.shared

    @StateObject private var navigationManager = NavigationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .accentColor(themeColor.swiftUIColor)
                .environmentObject(todaystampWatcher)
                .environmentObject(weatherStore)
                .environmentObject(CalendarStore.shared)
                .environmentObject(navigationManager)
                .onAppear {
                    Task {
                        await weatherStore.loadWeather()
                    }

                    if lastCleanedDatestamp != todaystampWatcher.todaystamp {
                        lastCleanedDatestamp = todaystampWatcher.todaystamp
                        cleanupAppData()
                    }
                }
        }
        .modelContainer(for: [
            Planner.self, ChecklistItem.self, CalendarSettings.self,
        ])
    }

    // Runs once at the start of every day to cleanup old data.
    private func cleanupAppData() {
        // 1: Delete canceled plans. First: add setting "Delete canceled plans: Never/Start of day"
        // 2: Delete planners older than chosen delay. First: add setting "Delete planners after: 1 month/3 months/6 months/Never"
        // 3: Delete calendar event positions from map that no longer exist.
    }

}
