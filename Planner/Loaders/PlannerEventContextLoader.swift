//
//  PlannerEventContextLoader.swift
//  Planner
//
//  Created by Alex Green on 5/13/26.
//

import Contacts
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
                if event.calendarContext != nil {
                    return false
                } else if let time = event.time {
                    return time >= dayStartDate && time < nextDayStartDate
                } else if let datestamp = event.datestamp {
                    return datestamp == plannerDatestamp
                } else {
                    return false
                }
            },
            sort: \.sortDate
        )

        _sortedEventChips = Query(
            filter: #Predicate<PlannerEvent> { event in
                if let calendarContext = event.calendarContext {
                    return calendarContext.birthdayContactIdentifier == nil
                        && calendarContext.isAllDay
                        && calendarContext.startDate < nextDayStartDate
                        && calendarContext.endDate >= dayStartDate
                } else {
                    return false
                }
            },
            sort: [
                SortDescriptor(
                    \PlannerEvent.title,
                    comparator: .localizedStandard
                )
            ]
        )

        _sortedBirthdayChips = Query(
            filter: #Predicate<PlannerEvent> { event in
                if let calendarContext = event.calendarContext {
                    return calendarContext.birthdayContactIdentifier != nil
                        && calendarContext.startDate < nextDayStartDate
                        && calendarContext.endDate >= dayStartDate
                } else {
                    return false
                }
            },
            sort: [
                SortDescriptor(
                    \PlannerEvent.title,
                    comparator: .localizedStandard
                )
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
    @Query private var sortedEventChips: [PlannerEvent]
    @Query private var sortedBirthdayChips: [PlannerEvent]

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
                sortedEventChips: sortedEventChips,
                sortedBirthdayChips: sortedBirthdayChips
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
        plannerSyncService.syncPlanner(
            planner,
            startOfDay: startOfDay,
            todaystamp: todayService.todaystamp,
            ekEventStore: calendarService.ekEventStore,
            modelContext: modelContext,
            settings: settings
        )
    }

    private func loadWeather() {
        Task {
            await weatherCacheService.ensureWeather(
                location: plannerLocation,
                region: startOfDay.region
            )
        }
    }
}
