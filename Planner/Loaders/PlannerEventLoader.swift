//
//  PlannerEventLoader.swift
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

struct PlannerEventContextLoaderView<Content: View>: View {
    private let plannerContext: PlannerContext
    private let settings: PlannerSettings
    private var content: (PlannerContext, PlannerEventContext) -> Content

    init(
        plannerContext: PlannerContext,
        plannerSyncService: PlannerSyncService,
        settings: PlannerSettings,
        @ViewBuilder content:
            @escaping (PlannerContext, PlannerEventContext) -> Content
    ) {
        self.plannerContext = plannerContext
        self.settings = settings
        self.content = content

        let startOfNextDay = (plannerContext.plannerDay + 1.days)
        let plannerDatestamp = plannerContext.planner.datestamp
        let dayStart = plannerContext.plannerDay.date
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

        _calendarDayData = State(
            initialValue: plannerSyncService.freshCalendarMap[
                plannerContext.planner.key
            ]
        )
    }

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var plannerSyncStore: PlannerSyncService
    @EnvironmentObject private var todaystampService: TodaystampService
    @EnvironmentObject private var plannerEngine: ListEngine<PlannerEvent>

    @Query private var sortedPlannerEvents: [PlannerEvent]

    @State private var calendarDayData: CalendarDayData?

    var body: some View {
        ZStack {
            content(
                plannerContext,
                PlannerEventContext(
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

        .onChange(of: plannerContext.plannerLocation) {
            oldLocation,
            newLocation in
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
        guard
            let weekday = Weekday.forDatestamp(plannerContext.planner.datestamp)
        else {
            return
        }

        let calendarData = await plannerSyncStore.syncPlanner(
            plannerContext.planner,
            weekday: weekday,
            plannerDay: plannerContext.plannerDay,
            sortedPlannerEvents: sortedPlannerEvents,
            settings: settings,
            ekEventStore: calendarStore.ekEventStore,
            todaystamp: todaystampService.todaystamp,
            modelContext: modelContext
        ).value

        withAnimation {
            calendarDayData = calendarData
        }

        hydrateCalendarEvents(calendarDayData: calendarData)
    }

    private func loadWeather() {
        Task {
            await weatherStore.loadWeatherIfNeeded(
                location: plannerContext.plannerLocation,
                region: plannerContext.plannerDay.region
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
