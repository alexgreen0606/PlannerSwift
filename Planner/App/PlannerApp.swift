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
        let locationService = LocationService()

        _locationService = StateObject(
            wrappedValue: locationService
        )

        _weatherStore = StateObject(
            wrappedValue: WeatherCacheService(
                locationService: locationService
            )
        )
    }

    @StateObject private var weatherStore: WeatherCacheService
    @StateObject private var locationService: LocationService

    private let modelContainer: ModelContainer = {
        let schema = Schema([
            PlannerSettings.self,
            Planner.self,
            PlannerEvent.self,
            ChecklistItem.self,
            Trip.self,
            RoutineEvent.self,
            RoutineEventVariant.self,
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

    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme
        .dark

    @StateObject private var calendarStore = CalendarService()
    @StateObject private var todaystampService = TodayService()
    @StateObject private var plannerCoverStore = PlannerCoverStore()
    @StateObject private var plannerSyncService = PlannerSyncService()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(appColorScheme.colorScheme)
                .environmentObject(todaystampService)
                .environmentObject(weatherStore)
                .environmentObject(calendarStore)
                .environmentObject(locationService)
                .environmentObject(plannerCoverStore)
                .environmentObject(plannerSyncService)
        }
        .modelContainer(modelContainer)
    }
}
