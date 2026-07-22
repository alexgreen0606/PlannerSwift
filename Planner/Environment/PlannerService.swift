//
//  PlannerService.swift
//  Planner
//
//  Created by Alex Green on 4/14/26.
//

import Combine
import EventKit
import Fuse
import SwiftData
import SwiftDate
import SwiftUI
import WeatherKit

@MainActor
class PlannerService: ObservableObject {
    private let modelContext: ModelContext
    private let calendarService: CalendarService
    private let todayService: TodayService
    private let locationService: LocationService
    private let plannerCoverStore: PlannerCoverStore
    private let settings: Settings

    init(
        modelContext: ModelContext,
        calendarService: CalendarService,
        todayService: TodayService,
        locationService: LocationService,
        plannerCoverStore: PlannerCoverStore,
        settings: Settings
    ) {
        self.modelContext = modelContext
        self.calendarService = calendarService
        self.todayService = todayService
        self.locationService = locationService
        self.plannerCoverStore = plannerCoverStore
        self.settings = settings

        self.searchService = SearchService(
            modelContainer: modelContext.container
        )

        self.searchResults = SearchResults(
            activeQuery: modelContext.defaultSearchQuery(
                todaystamp: todayService.todaystamp,
                settings: settings
            )
        )
    }

    private let searchService: SearchService
    private let weatherService = WeatherService()

    @AppStorage("lastRefresh") private var lastRefresh: Double = 0

    /// Planner location keys that have synced with the calendar.
    private var freshCalendarTimeZoneDateIds: Set<String> = []

    /// Panner datestamps that have synced with their routine.
    private var freshRoutineDatestamps: Set<String> = []

    /// Weather coordinate IDs that have synced with WeatherKit.
    private var freshWeatherCoordinateIds: Set<String> = []

    /// Bypasses the "don't sync routines of past planners" rule.
    private var forceSyncRoutineDatestamps: Set<String> = []

    @Published private(set) var thisWeekDatestamps: [String] = []

    @Published private(set) var sortedUpcomingTrips: [Trip] = []

    @Published private(set) var searchResults: SearchResults

    private var visibleDatestamps: Set<String> {
        var datestampsToSync: Set<String> = []

        if plannerCoverStore.showTodayDefault {
            datestampsToSync.insert(plannerCoverStore.todaystampAtInit)
        }

        if let datestamp = plannerCoverStore.context?.datestamp {
            datestampsToSync.insert(datestamp)
        }

        datestampsToSync.formUnion(
            sortedUpcomingTrips
                .flatMap(\.sortedPlanners)
                .map(\.datestamp)
        )

        datestampsToSync.formUnion(thisWeekDatestamps)

        datestampsToSync.formUnion(
            Set(
                searchResults.datestampMap.values.flatMap { $0 }
            )
        )

        return datestampsToSync
    }

    // MARK: - Search

    func search(with query: SearchQuery) {
        guard
            !calendarService.isOnboardingCalendars
        else { return }

        modelContext.safeSave("PlannerService search")

        Task {
            let datestampMap = await searchService.search(
                query: query,
                visibleCalendars: calendarService.sortedVisibleCalendars,
                ekEventStore: calendarService.ekEventStore,
                settings: settings
            )

            guard !Task.isCancelled else { return }

            // Sync the result planners.

            let planners = modelContext.getBulkPlanners(
                for: Set(datestampMap.values.flatMap { $0 })
            )

            for planner in planners {
                syncPlanner(planner)
            }

            // Return results so the UI can display them.
            await MainActor.run {
                let sortedKeys = datestampMap.keys.sorted {
                    query.past ? $0 > $1 : $0 < $1
                }

                let top = sortedKeys.first.flatMap { datestampMap[$0]?.first }

                withAnimation {
                    self.searchResults = SearchResults(
                        datestampMap: datestampMap,
                        topDatestamp: top,
                        sortedYears: sortedKeys,
                        activeQuery: query
                    )
                }
            }
        }
    }

    func search() {
        search(with: searchResults.activeQuery)
    }

    // MARK: - Synchronization

    func syncPlanner(datestamp: String) {
        let planner = modelContext.getPlanner(for: datestamp)
        syncPlanner(planner)
    }

    func syncPlanner(_ planner: Planner) {
        guard settings.homeLocation != nil
        else { return }

        let datestamp = planner.datestamp
        let startOfDay = planner.startOfDay(settings: settings)

        // Sync routine.
        if !freshRoutineDatestamps.contains(
            datestamp
        ) {
            freshRoutineDatestamps.insert(datestamp)

            modelContext.syncRoutine(
                for: planner,
                startOfDay: startOfDay,
                todayStartOfDay: todayService.todayPlanner.startOfDay(
                    settings: settings
                ),
                syncPast: forceSyncRoutineDatestamps.contains(datestamp),
                ekEventStore: calendarService.ekEventStore
            )

            forceSyncRoutineDatestamps.remove(datestamp)
        }

        // Sync weather for the planners coming up this week.
        if thisWeekDatestamps.contains(planner.datestamp),
            let location = planner.location(
                settings: settings,
                deviceLocation: locationService.deviceLocation
            ),
            !freshWeatherCoordinateIds.contains(location.coordinateId)
        {
            let existingWeather = modelContext.getPlannerWeather(
                for: startOfDay.date,
                at: location.coordinateId
            )

            if existingWeather.needsRefresh(lastRefresh: lastRefresh) {
                freshWeatherCoordinateIds.insert(location.coordinateId)

                Task {
                    await modelContext.syncWeather(
                        location: location,
                        startOfDay: startOfDay,
                        weatherService: weatherService
                    )
                }
            }
        }

        guard
            !calendarService.isOnboardingCalendars
        else { return }

        let timeZoneDateId = planner.timeZoneDateId

        // Sync calendar.
        if !freshCalendarTimeZoneDateIds.contains(timeZoneDateId) {
            freshCalendarTimeZoneDateIds.insert(timeZoneDateId)

            modelContext.syncCalendar(
                startOfDay: startOfDay,
                calendarService: calendarService,
                settings: settings
            )
        }
    }
    
    func syncVisiblePlanners() {
        let planners = modelContext.getBulkPlanners(for: visibleDatestamps)
        for planner in planners {
            syncPlanner(planner)
        }
    }

    // MARK: - Refresh (invalidate and sync)

    func refresh() {
        invalidateRoutines()
        invalidateCalendar()
        invalidateWeather()
        loadVisibleDatestamps()
        syncVisiblePlanners()
    }

    func refreshCalendar() {
        invalidateCalendar()
        syncVisiblePlanners()
    }

    func refreshPlannerRoutine(planner: Planner) {
        let datestamp = planner.datestamp

        freshRoutineDatestamps.remove(datestamp)
        forceSyncRoutineDatestamps.insert(datestamp)
        syncPlanner(planner)
    }

    // MARK: - Invalidation
    /// Note: Only invalidate when you expect external data to have changed (not when the window you are searching changes).

    func invalidateRoutines() {
        freshRoutineDatestamps = []
    }

    private func invalidateCalendar() {
        freshCalendarTimeZoneDateIds = []
    }

    private func invalidateWeather() {
        lastRefresh = Date.now.timeIntervalSince1970
        freshWeatherCoordinateIds = []
    }

    // MARK: - Change Handlers

    func handleTripChange() {
        withAnimation {
            loadTrips()
        }

        invalidateRoutines()
        syncVisiblePlanners()
    }

    // MARK: - Loaders

    private func loadVisibleDatestamps() {
        withAnimation {
            loadThisWeekDatestamps()
            loadTrips()
        }
    }

    private func loadTrips() {
        sortedUpcomingTrips = modelContext.getSortedTrips(
            onOrBefore: todayService.todaystamp
        )
    }

    private func loadThisWeekDatestamps() {
        thisWeekDatestamps = (0..<7).map { offset in
            DateInRegion(region: .local)
                .dateByAdding(offset, .day)
                .datestamp
        }
    }
}
