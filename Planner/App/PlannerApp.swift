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

        _weatherCacheService = StateObject(
            wrappedValue: WeatherCacheService(
                locationService: locationService
            )
        )
    }

    @StateObject private var weatherCacheService: WeatherCacheService
    @StateObject private var locationService: LocationService

    private let modelContainer: ModelContainer = {
        let schema = Schema([
            Settings.self,
            
            Location.self,
            
            Trip.self,
            
            Planner.self,
            PlannerEvent.self,
            EKEventContext.self,
            RoutineEventRecordContext.self,
            
            ChecklistItem.self,
            
            Routine.self,
            RoutineEvent.self,
            RoutineEventContext.self
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

    @StateObject private var plannerCoverStore = PlannerCoverStore()
    @StateObject private var locationSearchService = LocationSearchService()

    var body: some Scene {
        WindowGroup {
            RootLoaderView()
                .preferredColorScheme(appColorScheme.colorScheme)
                .environmentObject(weatherCacheService)
                .environmentObject(locationService)
                .environmentObject(plannerCoverStore)
                .environmentObject(locationSearchService)
        }
        .modelContainer(modelContainer)
    }
}
