//
//  PlannerApp.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftData
import SwiftUI

// Clean

@main
struct PlannerApp: App {

    init() {

        let deviceLocationManager = DeviceLocationManager()

        _deviceLocationManager = StateObject(
            wrappedValue: deviceLocationManager
        )
        _weatherStore = StateObject(
            wrappedValue: WeatherStore(
                deviceLocationManager: deviceLocationManager
            )
        )
    }
    
    private let container: ModelContainer = {
        let schema = Schema([
            PlannerSettings.self,
            Planner.self,
            PlannerEvent.self,
            ChecklistItem.self,
            Trip.self,
            RoutineEvent.self,
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .automatic
        )

        return try! ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }()

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme
        .dark

    @StateObject private var calendarStore = CalendarStore()
    @StateObject private var todaystampWatcher = TodaystampWatcher()
    @StateObject private var plannerCoverManager = PlannerCoverManager()
    @StateObject private var plannerBuildManager = PlannerBuildManager()

    @StateObject private var weatherStore: WeatherStore
    @StateObject private var deviceLocationManager: DeviceLocationManager

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appColorScheme.colorScheme)
                .accentColor(accentColor.color)
                .environmentObject(todaystampWatcher)
                .environmentObject(weatherStore)
                .environmentObject(calendarStore)
                .environmentObject(deviceLocationManager)
                .environmentObject(plannerCoverManager)
                .environmentObject(plannerBuildManager)
        }
        .modelContainer(container)
    }
}
