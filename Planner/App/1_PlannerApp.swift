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

    private let modelContainer: ModelContainer = {
        let schema = Schema([
            Settings.self,

            Location.self,

            Trip.self,

            Planner.self,
            PlannerEvent.self,
            EKEventContext.self,
            RoutineEventRecordContext.self,
            PlannerWeather.self,

            ChecklistItem.self,

            Routine.self,
            RoutineEvent.self,
            RoutineEventContext.self,
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

    @StateObject private var locationService = LocationService()
    @StateObject private var plannerCoverStore = PlannerCoverStore()
    @StateObject private var locationSearchService = LocationSearchService()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            DataLoaderView()
                .preferredColorScheme(appColorScheme.colorScheme)
                .environmentObject(locationService)
                .environmentObject(plannerCoverStore)
                .environmentObject(locationSearchService)
        }
        .modelContainer(modelContainer)
    }
}
