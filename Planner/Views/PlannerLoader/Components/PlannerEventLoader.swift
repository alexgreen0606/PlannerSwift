//
//  PlannerEventLoaderView.swift
//  Planner
//
//  Created by Alex Green on 5/13/26.
//

import Contacts
import ContactsUI
import EventKit
import SwiftData
import SwiftDate
import SwiftUI

struct PlannerEventLoaderView<Content: View>: View {
    private let planner: Planner
    private let plannerDay: DateInRegion
    private let plannerLocation: Location?
    private let settings: PlannerSettings
    private var content: (PlannerContext) -> Content

    init(
        planner: Planner,
        plannerDay: DateInRegion,
        plannerLocation: Location?,
        settings: PlannerSettings,
        @ViewBuilder content: @escaping (PlannerContext) -> Content
    ) {
        self.planner = planner
        self.plannerDay = plannerDay
        self.plannerLocation = plannerLocation
        self.settings = settings
        self.content = content

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
    @EnvironmentObject private var plannerSyncStore: PlannerSyncStore
    @EnvironmentObject private var todaystampService: TodaystampService

    @Query private var sortedPlannerEvents: [PlannerEvent]

    @State private var calendarDayData: CalendarDayData?

    var body: some View {
        ZStack {
            content(
                PlannerContext(
                    planner: planner,
                    plannerDay: plannerDay,
                    plannerLocation: plannerLocation,
                    sortedPlannerEvents: sortedPlannerEvents,
                    calendarDayData: calendarDayData
                )
            )
        }
        .task(id: plannerSyncStore.rebuildTrigger) {
            await buildPlanner()
        }
        .task(id: weatherStore.reloadTrigger) {
            loadWeather()
        }

        // MARK: Reload the weather and calendar events when the time zone changes.
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

    // MARK: - Functions

    @MainActor
    private func buildPlanner() async {
        guard let weekday = Weekday.forDatestamp(planner.datestamp) else {
            return
        }

        let calendarData = await plannerSyncStore.syncPlanner(
            planner,
            weekday: weekday,
            plannerDay: plannerDay,
            sortedPlannerEvents: sortedPlannerEvents,
            settings: settings,
            ekEventStore: calendarStore.ekEventStore,
            todaystamp: todaystampService.todaystamp,
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
