//
//  PlannerEventBuilderView.swift
//  Planner
//
//  Created by Alex Green on 2/28/26.
//

import SwiftData
import SwiftDate
import SwiftUI
import EventKit

struct PlannerEventBuilderView: View {
    private let planner: Planner
    private let settings: PlannerSettings
    private let previewType: PlannerPreviewType?
    private let namespace: Namespace.ID?

    private let plannerStartOfDay: DateInRegion

    init(
        planner: Planner,
        settings: PlannerSettings,
        previewType: PlannerPreviewType? = nil,
        namespace: Namespace.ID? = nil
    ) {
        self.planner = planner
        self.previewType = previewType
        self.settings = settings
        self.namespace = namespace

        let region = planner.region(settings: settings)

        guard let startOfDay = planner.datestamp.startOfDay(in: region) else {
            fatalError(
                "ERROR PlannerDataBuilder.init: Could not get DateInRegion from: \(planner.datestamp)"
            )
        }

        let startOfNextDay = (startOfDay + 1.days)

        _sortedPlannerEvents = Query(
            filter: #Predicate<PlannerEvent> { event in
                if !event.hasTime {
                    return event.date == startOfDay.date
                } else {
                    return event.date >= startOfDay.date &&
                           event.date < startOfNextDay.date
                }
            },
            sort: \.sortDate
        )

        self.plannerStartOfDay = startOfDay
    }

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    @Query private var sortedPlannerEvents: [PlannerEvent]

    @State private var allDayEvents: [EKEvent] = []

    private var plannerLocation: Location? {
        planner.location(
            settings: settings,
            deviceLocation: deviceLocationManager.location
        )
    }

    private var plannerRegion: Region {
        planner.region(settings: settings)
    }

    var body: some View {
        ZStack {
            if previewType != nil {
                previewView
            } else {
                expandedView
            }
        }

        // Calendar data tracking.
        .externalData(
            key: calendarStore.loadTrigger,
            ready: true,
            load: loadCalendarData
        )

        // Weather data tracking.
        .externalData(
            key: weatherStore.loadTrigger,
            ready: true,
            load: loadWeatherData
        )

        // Reload the weather and events when the location changes.
        .onChange(of: plannerLocation) { _, _ in
            loadCalendarData()

            Task {
                await weatherStore.loadWeatherIfNeeded(
                    location: plannerLocation,
                    region: plannerRegion
                )
            }
        }
    }

    @ViewBuilder
    private var expandedView: some View {
            ExpandedPlannerView(
                planner: planner,
                plannerStartOfDay: plannerStartOfDay,
                plannerLocation: plannerLocation,
                sortedPlannerEvents: sortedPlannerEvents,
                allDayEvents: allDayEvents,
                settings: settings
            )
    }

    @ViewBuilder
    private var previewView: some View {
        if let previewType, let namespace {
            PlannerPreviewView(
                planner: planner,
                plannerStartOfDay: plannerStartOfDay,
                plannerLocation: plannerLocation,
                sortedPlannerEvents: sortedPlannerEvents,
                allDayEvents: allDayEvents,
                settings: settings,
                type: previewType
            )
            .matchedTransitionSource(
                id: planner.datestamp,
                in: namespace
            )
        }
    }

    private func loadCalendarData() {
        allDayEvents = calendarStore.syncCalendarEvents(
            for: planner,
            storageEvents: sortedPlannerEvents,
            plannerStartOfDay: plannerStartOfDay,
            hiddenCalendarIds: settings.hiddenCalendarIds,
            modelContext: modelContext
        )
    }

    private func loadWeatherData() {
        Task {
            await weatherStore.loadWeatherIfNeeded(
                location: plannerLocation,
                region: plannerStartOfDay.region
            )
        }
    }
    
}
