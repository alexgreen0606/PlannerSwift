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

        let plannerDatestamp = planner.datestamp
        let dayStart = plannerDay.date
        let nextDay = startOfNextDay.date

        _sortedPlannerEvents = Query(
            filter: #Predicate<PlannerEvent> { event in
                if let time = event.time {
                    return time >= dayStart && time < nextDay
                } else if let datestamp = event.datestamp {
                    return datestamp == plannerDatestamp
                } else {
                    return false
                }
            },
            sort: \.sortDate
        )
    }

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var plannerBuildManager: PlannerBuildManager
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher

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

        // MARK: Reload the weather and calendar events when the location changes.
        .onChange(of: plannerLocation) { oldLocation, newLocation in
            loadWeather()

            let current = TimeZone.current.identifier
            let oldTimeZoneIdentifier =
                oldLocation?.timeZoneIdentifier ?? current
            let newTimeZoneIdentifier =
                newLocation?.timeZoneIdentifier ?? current

            if oldTimeZoneIdentifier != newTimeZoneIdentifier {
                Task {
                    await buildPlanner()
                }
            }
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
        guard let weekday = Weekday.forDatestamp(planner.datestamp) else {
            return
        }

        let calendarData = await plannerBuildManager.syncPlanner(
            planner,
            weekday: weekday,
            plannerDay: plannerDay,
            sortedPlannerEvents: sortedPlannerEvents,
            settings: settings,
            ekEventStore: calendarStore.ekEventStore,
            todaystamp: todaystampWatcher.todaystamp,
            modelContext: modelContext,
        ).value

        withAnimation {
            calendarDayData = calendarData
        }

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
