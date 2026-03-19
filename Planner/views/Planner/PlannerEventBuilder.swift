//
//  PlannerEventBuilder.swift
//  Planner
//
//  Created by Alex Green on 2/28/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

// Clean

struct PlannerEventBuilderView: View {
    private let planner: Planner
    private let settings: PlannerSettings
    private let previewType: PlannerPreviewType?
    private let plannerSearchQuery: PlannerSearchQuery?
    private let namespace: Namespace.ID?

    init(
        planner: Planner,
        settings: PlannerSettings,
        previewType: PlannerPreviewType? = nil,
        plannerSearchQuery: PlannerSearchQuery? = nil,
        namespace: Namespace.ID? = nil
    ) {
        self.planner = planner
        self.previewType = previewType
        self.plannerSearchQuery = plannerSearchQuery
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
                    return event.date >= startOfDay.date
                        && event.date < startOfNextDay.date
                }
            },
            sort: \.sortDate
        )

        self.plannerDay = startOfDay
    }

    private let plannerDay: DateInRegion

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    @Query private var sortedPlannerEvents: [PlannerEvent]

    @State private var plannerChipEvents: [EKEvent] = []

    private var plannerLocation: Location? {
        planner.location(
            settings: settings,
            deviceLocation: deviceLocationManager.deviceLocation
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
            key: calendarStore.reloadTrigger,
            ready: true,
            load: loadCalendarData
        )

        // Weather data tracking.
        .externalData(
            key: weatherStore.reloadTrigger,
            ready: true,
            load: loadWeatherData
        )

        // Reload the weather and events when the location changes.
        .onChange(of: plannerLocation) { _, _ in
            loadCalendarData()
            loadWeatherData()
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private var expandedView: some View {
        ExpandedPlannerView(
            planner: planner,
            plannerDay: plannerDay,
            plannerLocation: plannerLocation,
            sortedPlannerEvents: sortedPlannerEvents,
            plannerChipEvents: plannerChipEvents,
            settings: settings
        )
    }

    @ViewBuilder
    private var previewView: some View {
        if let previewType, let namespace {
            PlannerPreviewView(
                type: previewType,
                searchQuery: plannerSearchQuery,
                planner: planner,
                plannerDay: plannerDay,
                plannerLocation: plannerLocation,
                plannerEvents: sortedPlannerEvents,
                plannerChipEvents: plannerChipEvents,
                settings: settings
            )
            .matchedTransitionSource(
                id: planner.datestamp,
                in: namespace
            )
        }
    }

    // MARK: - Functions

    private func loadCalendarData() {

        let plannerKey = planner.key

        // Return cached data.
        if let existingData = calendarStore.allDayEventsByPlannerKey[plannerKey]
        {
            plannerChipEvents = existingData
            return
        }

        let calendarSearchResults = modelContext.syncCalendarEvents(
            for: planner,
            storageEvents: sortedPlannerEvents,
            plannerDay: plannerDay,
            hiddenCalendarIds: settings.hiddenCalendarIds,
            ekEventStore: calendarStore.ekEventStore
        )

        plannerChipEvents = calendarSearchResults.plannerChipEvents

        calendarStore.cachePlannerChips(
            plannerChipEvents,
            plannerKey: plannerKey
        )

        DispatchQueue.main.async {
            hydrateCalendarEvents(calendarSearchResults: calendarSearchResults)
        }
    }

    private func loadWeatherData() {
        Task {
            await weatherStore.loadWeatherIfNeeded(
                location: plannerLocation,
                region: plannerDay.region
            )
        }
    }

    private func hydrateCalendarEvents(
        calendarSearchResults: CalendarSearchResults
    ) {
        for event in sortedPlannerEvents {
            if let calendarItemExternalIdentifier = event
                .calendarItemExternalIdentifier
            {
                if let occurrenceId = event.occurrenceId {
                    event.calendarEvent =
                        calendarSearchResults.occurrenceEvents[occurrenceId]
                } else {
                    event.calendarEvent =
                        calendarSearchResults.regularEvents[
                            calendarItemExternalIdentifier
                        ]
                }
            }
        }
    }

}
