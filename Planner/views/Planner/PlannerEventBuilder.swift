//
//  PlannerEventBuilder.swift
//  Planner
//
//  Created by Alex Green on 2/28/26.
//

import Contacts
import ContactsUI
import EventKit
import SwiftData
import SwiftDate
import SwiftUI

// Clean

struct PlannerEventBuilderView<Header: View>: View {
    private let planner: Planner
    private let plannerDay: DateInRegion
    private let plannerLocation: Location?
    private let settings: PlannerSettings
    private let previewType: PlannerPreviewType?
    private let plannerSearchQuery: PlannerSearchQuery?
    private let header: Header

    init(
        planner: Planner,
        plannerDay: DateInRegion,
        plannerLocation: Location?,
        settings: PlannerSettings,
        previewType: PlannerPreviewType? = nil,
        plannerSearchQuery: PlannerSearchQuery? = nil,
        header: Header
    ) {
        self.planner = planner
        self.plannerDay = plannerDay
        self.plannerLocation = plannerLocation
        self.previewType = previewType
        self.plannerSearchQuery = plannerSearchQuery
        self.header = header
        self.settings = settings

        let startOfNextDay = (plannerDay + 1.days)

        _sortedPlannerEvents = Query(
            filter: #Predicate<PlannerEvent> { event in
                if !event.hasTime {
                    return event.date == plannerDay.date
                } else {
                    return event.date >= plannerDay.date
                        && event.date < startOfNextDay.date
                }
            },
            sort: \.sortDate
        )
    }

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var weatherStore: WeatherStore

    @Query private var sortedPlannerEvents: [PlannerEvent]

    @State private var calendarDayData: CalendarDayData?

    var body: some View {
        ZStack {
            if previewType != nil {
                previewView
            } else {
                expandedView
            }
        }
        
        // Track up-to-date calendar data.
        .task(id: calendarStore.reloadTrigger) {
            loadCalendarData()
        }
        
        // Track up-to-date weather data.
        .task(id: weatherStore.reloadTrigger) {
            loadWeatherData()
        }

        // Reload the weather and events when the location changes.
        .onChange(of: plannerLocation) { _, _ in
            loadCalendarData()
            loadWeatherData()
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private var expandedView: some View {
        if let calendarDayData {
            ExpandedPlannerView(
                planner: planner,
                header: header,
                plannerDay: plannerDay,
                plannerLocation: plannerLocation,
                sortedPlannerEvents: sortedPlannerEvents,
                calendarDayData: calendarDayData,
                settings: settings
            )
        }
    }

    @ViewBuilder
    private var previewView: some View {
        if let previewType, let calendarDayData {
            PlannerPreviewView(
                type: previewType,
                searchQuery: plannerSearchQuery,
                header: header,
                planner: planner,
                plannerDay: plannerDay,
                plannerLocation: plannerLocation,
                plannerEvents: sortedPlannerEvents,
                calendarDayData: calendarDayData,
                settings: settings
            )
            .transition(.opacity)
        }
    }

    // MARK: - Functions

    private func loadCalendarData() {

        let plannerKey = planner.key

        // Return cached data.
        if let existingData = calendarStore.cache[plannerKey] {
            calendarDayData = existingData
            return
        }

        withAnimation {
            calendarDayData = modelContext.buildPlanner(
                for: planner,
                storageEvents: sortedPlannerEvents,
                plannerDay: plannerDay,
                hiddenCalendarIds: settings.hiddenCalendarIds,
                ekEventStore: calendarStore.ekEventStore
            )
        }

        if let calendarDayData {
            calendarStore.cacheData(
                calendarDayData,
                plannerKey: plannerKey
            )
        }

        DispatchQueue.main.async {
            hydrateCalendarEvents()
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

    private func hydrateCalendarEvents() {
        if let calendarDayData {
            for event in sortedPlannerEvents {
                if let calendarItemExternalIdentifier = event
                    .calendarItemExternalIdentifier
                {
                    if let occurrenceId = event.occurrenceId {
                        event.calendarEvent =
                            calendarDayData.occurrenceEvents[occurrenceId]
                    } else {
                        event.calendarEvent =
                            calendarDayData.regularEvents[
                                calendarItemExternalIdentifier
                            ]
                    }
                }
            }
        }
    }

}
