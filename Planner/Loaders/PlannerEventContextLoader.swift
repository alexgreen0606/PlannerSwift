//
//  PlannerEventContextLoader.swift
//  Planner
//
//  Created by Alex Green on 5/13/26.
//

import SwiftData
import SwiftDate
import SwiftUI

struct PlannerEventContextLoaderView<Content: View>: View {
    private let planner: Planner
    private let settings: PlannerSettings
    private var content: (PlannerEventContext) -> Content

    init(
        planner: Planner,
        plannerSyncService: PlannerSyncService,
        settings: PlannerSettings,
        @ViewBuilder content:
        @escaping (PlannerEventContext) -> Content
    ) {
        self.planner = planner
        self.settings = settings
        self.content = content

        let startOfDay = planner.startOfDay(settings: settings)
        let startOfNextDay = (startOfDay + 1.days)
        let dayStartDate = startOfDay.date
        let nextDayStartDate = startOfNextDay.date

        let plannerDatestamp = planner.datestamp

        _sortedPlannerEvents = Query(
            filter: #Predicate<PlannerEvent> { event in
                if let time = event.time {
                    return time >= dayStartDate && time < nextDayStartDate
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
                planner.plannerLocationId
            ]
        )

        self.startOfDay = startOfDay
    }

    private let startOfDay: DateInRegion

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var weatherCacheService: WeatherCacheService
    @EnvironmentObject private var plannerSyncService: PlannerSyncService
    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var locationService: LocationService

    @Query private var sortedPlannerEvents: [PlannerEvent]

    @State private var calendarDayData: CalendarDayData?

    private var plannerLocation: Location? {
        planner.location(
            settings: settings,
            deviceLocation: locationService.deviceLocation
        )
    }

    // MARK: - Body

    var body: some View {
        content(
            PlannerEventContext(
                sortedPlannerEvents: sortedPlannerEvents,
                calendarDayData: calendarDayData
            )
        )
        .task(id: plannerSyncService.syncTrigger) {
            syncPlanner()
        }
        .task(id: weatherCacheService.reloadTrigger) {
            loadWeather()
        }

        // MARK: Reload the weather and calendar events when the time zone changes.

        .onChange(of: plannerLocation) {
            oldLocation,
            newLocation in
            loadWeather()

            let deviceTimeZoneIdentifier = TimeZone.current.identifier
            let oldTimeZoneIdentifier =
                oldLocation?.timeZoneIdentifier ?? deviceTimeZoneIdentifier
            let newTimeZoneIdentifier =
                newLocation?.timeZoneIdentifier ?? deviceTimeZoneIdentifier

            if oldTimeZoneIdentifier != newTimeZoneIdentifier {
                // The 24-hour time window has changed. Sync the planner again to get accurate calendar events.
                syncPlanner()
            }
        }
    }

    // MARK: - Functions

    @MainActor
    private func syncPlanner() {
        Task {
            guard
                let calendarData = await plannerSyncService.syncPlanner(
                    planner,
                    startOfDay: startOfDay,
                    sortedPlannerEvents: sortedPlannerEvents,
                    todaystamp: todayService.todaystamp,
                    ekEventStore: calendarService.ekEventStore,
                    modelContext: modelContext,
                    settings: settings
                ).value
            else { return }

            withAnimation {
                calendarDayData = calendarData
                hydrateCalendarEvents(calendarDayData: calendarData)
            }
        }
    }

    private func loadWeather() {
        Task {
            await weatherCacheService.ensureWeather(
                location: plannerLocation,
                region: startOfDay.region
            )
        }
    }

    /// Links calendar events to their accompanying planner event.
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
