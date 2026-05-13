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

        let LocationService = LocationService()

        _locationService = StateObject(
            wrappedValue: LocationService
        )
        _weatherStore = StateObject(
            wrappedValue: WeatherStore(
                LocationService: LocationService
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
            RoutineEventVariant.self
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
    @StateObject private var todaystampService = TodaystampService()
    @StateObject private var plannerCoverStore = PlannerCoverStore()
    @StateObject private var plannerSyncStore = PlannerSyncStore()

    @StateObject private var weatherStore: WeatherStore
    @StateObject private var locationService: LocationService

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(appColorScheme.colorScheme)
                .environmentObject(todaystampService)
                .environmentObject(weatherStore)
                .environmentObject(calendarStore)
                .environmentObject(locationService)
                .environmentObject(plannerCoverStore)
                .environmentObject(plannerSyncStore)
        }
        .modelContainer(container)
    }
}
