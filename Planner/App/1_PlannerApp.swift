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
            PlannerWeather.self,

            ChecklistItem.self,

            Routine.self,
            RoutineEvent.self,
            RoutineEventContext.self,

            EkEventPlannerState.self,

            // Note: These are deprecated in favor of the new PlannerItem approach.
            EKEventContext.self,
            RoutineEventRecordContext.self,
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("1_PlannerApp init: \(error)")
        }
    }()

    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme
        .dark

    @StateObject private var locationService = LocationService()
    @StateObject private var locationSearchService = LocationSearchService()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            DataLoaderView()
                .preferredColorScheme(appColorScheme.colorScheme)
                .environmentObject(locationService)
                .environmentObject(locationSearchService)
        }
        .modelContainer(modelContainer)
    }
}
