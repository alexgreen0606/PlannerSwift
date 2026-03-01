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

    init() {
        let locationManager = DeviceLocationManager()
        _locationManager = StateObject(wrappedValue: locationManager)
        _weatherStore = StateObject(
            wrappedValue: WeatherStore(locationManager: locationManager)
        )
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme
        .system

    @StateObject private var locationManager = DeviceLocationManager()
    @StateObject private var weatherStore: WeatherStore
    @StateObject private var calendarStore = CalendarStore()
    @StateObject private var todaystampWatcher = TodaystampWatcher()
    @StateObject private var plannerCoverManager = PlannerCoverManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appColorScheme.colorScheme)
                .accentColor(accentColor.swiftUIColor)
                .environmentObject(todaystampWatcher)
                .environmentObject(weatherStore)
                .environmentObject(calendarStore)
                .environmentObject(locationManager)
                .environmentObject(plannerCoverManager)
        }
        .modelContainer(for: [
            Planner.self, ChecklistItem.self, PlannerSettings.self,
            PlannerSettings.self, PlannerEvent.self
        ])
    }
}
