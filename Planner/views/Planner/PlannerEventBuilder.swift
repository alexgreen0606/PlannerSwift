//
//  PlannerEventBuilderView.swift
//  Planner
//
//  Created by Alex Green on 2/28/26.
//

import SwiftData
import SwiftDate
import SwiftUI

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

        _storageEvents = Query(
            filter: #Predicate<PlannerEvent> {
                $0.date >= startOfDay.date && $0.date < startOfNextDay.date
            }
        )

        self.plannerStartOfDay = startOfDay
    }

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    @Query private var storageEvents: [PlannerEvent]

    @State private var calendarData: PlannerCalendarData? = nil
    @State private var calendarPlannerEvents: [PlannerEvent] = []

    private var plannerLocation: Location? {
        planner.location(
            settings: settings,
            deviceLocation: deviceLocationManager.location
        )
    }

    private var plannerRegion: Region {
        planner.region(settings: settings)
    }

    private var allSortedPlannerEvents: [PlannerEvent] {
        (storageEvents + calendarPlannerEvents)
            .sorted {
                $0.sortDate < $1.sortDate
            }
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
        if let calendarData {
            ExpandedPlannerView(
                planner: planner,
                plannerStartOfDay: plannerStartOfDay,
                plannerLocation: plannerLocation,
                storageEvents: storageEvents,
                allSortedPlannerEvents: allSortedPlannerEvents,
                calendarData: calendarData,
                settings: settings
            )
        }
    }

    @ViewBuilder
    private var previewView: some View {
        if let previewType, let calendarData, let namespace {
            PlannerPreviewView(
                planner: planner,
                plannerStartOfDay: plannerStartOfDay,
                plannerLocation: plannerLocation,
                storageEvents: storageEvents,
                calendarPlannerEvents: calendarPlannerEvents,
                calendarData: calendarData,
                settings: settings,
                type: previewType
            )
            .matchedTransitionSource(
                id: planner.datestamp,
                in: namespace
            )

            // Rebuild the calendar events when their positions change.
            .onChange(of: settings.calendarSortDateMap) { _, _ in
                buildCalendarPlannerEvents(calendarData: calendarData)
            }
        }
    }

    private func loadCalendarData() {

        let calendarData = calendarStore.loadPlannerData(
            for: planner,
            plannerStartOfDay: plannerStartOfDay,
            hiddenCalendarIds: settings.hiddenCalendarIds
        )

        buildCalendarPlannerEvents(calendarData: calendarData)

        self.calendarData = calendarData
    }

    private func buildCalendarPlannerEvents(calendarData: PlannerCalendarData) {
        calendarPlannerEvents =
            modelContext.buildCalendarPlannerEvents(
                calendarEvents: calendarData.timedEvents,
                storageEvents: storageEvents,
                startOfDay: plannerStartOfDay,
                settings: settings,
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
