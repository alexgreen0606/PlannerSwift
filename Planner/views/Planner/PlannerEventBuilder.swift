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
    @EnvironmentObject private var plannerBuildManager: PlannerBuildManager

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
        .task(id: plannerBuildManager.rebuildTrigger) {
            await buildPlanner()
        }
        .task(id: weatherStore.reloadTrigger) {
            loadWeather()
        }

        // Reload the weather and events when the location changes.
        .onChange(of: plannerLocation) { _, _ in

            // TODO: why was I building the planner? when location changes? Maybe I should
            // do this from the homeLocation setting or the actual location sheet in planners?

            // buildPlanner()
            loadWeather()
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private var expandedView: some View {
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

    @MainActor
    private func buildPlanner() async {
        guard let weekday = Weekday.from(planner.datestamp.weekday) else {
            return
        }

        let calendarData = await plannerBuildManager.syncPlanner(
            planner,
            weekday: weekday,
            plannerDay: plannerDay,
            sortedPlannerEvents: sortedPlannerEvents,
            settings: settings,
            ekEventStore: calendarStore.ekEventStore,
            modelContext: modelContext
        ).value

        calendarDayData = calendarData
        hydrateCalendarEvents(calendarDayData: calendarData)
    }

    private func loadWeather() {
        Task {
            await weatherStore.loadWeatherIfNeeded(
                location: plannerLocation,
                region: plannerDay.region
            )
        }
    }

    private func hydrateCalendarEvents(calendarDayData: CalendarDayData) {
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
