//
//  EnvironmentLoader.swift
//  Planner
//
//  Created by Alex Green on 7/15/26.
//

import SwiftData
import SwiftUI

struct EnvironmentLoaderView: View {
    private let settings: Settings

    init(
        plannerCoverStore: PlannerCoverStore,
        locationService: LocationService,
        modelContext: ModelContext,
        settings: Settings
    ) {
        self.settings = settings

        let calendarService = CalendarService(settings: settings)
        let todayService = TodayService(settings: settings, modelContext: modelContext)

        self._plannerService = StateObject(
            wrappedValue: PlannerService(
                modelContext: modelContext,
                calendarService: calendarService,
                todayService: todayService,
                plannerCoverStore: plannerCoverStore,
                settings: settings
            )
        )
        self._calendarService = StateObject(
            wrappedValue: calendarService
        )
        self._todayService = StateObject(
            wrappedValue: todayService
        )
    }

    @EnvironmentObject private var locationService: LocationService

    @StateObject private var calendarService: CalendarService
    @StateObject private var todayService: TodayService
    @StateObject private var plannerService: PlannerService

    // MARK: - Body

    var body: some View {
        OnboardingView(
            locationService: locationService,
            settings: settings
        )
        .environmentObject(calendarService)
        .environmentObject(todayService)
        .environmentObject(plannerService)
    }
}
