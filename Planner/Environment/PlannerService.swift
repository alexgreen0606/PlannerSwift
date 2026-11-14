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
    private let plannerCoverStore: PlannerCoverStore
    private let settings: Settings

    init(
        modelContext: ModelContext,
        calendarService: CalendarService,
        todayService: TodayService,
        plannerCoverStore: PlannerCoverStore,
        settings: Settings
    ) {
        self.modelContext = modelContext
        self.calendarService = calendarService
        self.todayService = todayService
        self.plannerCoverStore = plannerCoverStore
        self.settings = settings

        self.searchService = SearchService(
            modelContainer: modelContext.container
        )

        self.plannerListContext = PlannerListContext(
            structuredDatestamps: StructuredDatestampsContext(
                datestamps: todayService.next30Datestamps
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

    @Published var expandedTripIds: Set<PersistentIdentifier> = []

    @Published private(set) var plannerListContext: PlannerListContext

    var activeQuery: PlannerSearchQuery? {
        plannerListContext.query
    }

    private var visibleDatestamps: Set<String> {
        var datestamps: Set<String> = []

        if plannerCoverStore.showTodayDefault {
            datestamps.insert(plannerCoverStore.todaystampAtInit)
        }

        if let datestamp = plannerCoverStore.context?.datestamp {
            datestamps.insert(datestamp)
        }

        if !expandedTripIds.isEmpty {
            let expandedTrips = modelContext.getTrips(matching: expandedTripIds)

            datestamps.formUnion(
                expandedTrips
                    .flatMap(\.sortedPlanners)
                    .map(\.datestamp)
            )
        }

        datestamps.formUnion(
            Set(
                plannerListContext.structuredDatestamps.datestamps
            )
        )

        return datestamps
    }

    // MARK: - Planner List Load/Search

    func loadPlannerList(matching query: PlannerSearchQuery?) {
        guard
            !calendarService.isOnboardingCalendars
        else { return }

        // No search params exist. Default the planner list and exit.
        guard let query, !query.isDefault
        else {
            plannerListContext = PlannerListContext(
                structuredDatestamps: StructuredDatestampsContext(
                    datestamps: todayService.next30Datestamps
                )
            )

            let planners = modelContext.getBulkPlanners(
                for: Set(plannerListContext.structuredDatestamps.datestamps)
            )

            syncPlanners(planners)

            return
        }

        modelContext.safeSave("PlannerService loadPlannerList")

        Task {
            let searchResults = await searchService.search(
                query: query,
                visibleCalendars: calendarService.sortedVisibleCalendars,
                ekEventStore: calendarService.ekEventStore,
                settings: settings
            )

            guard !Task.isCancelled else { return }

            // Return results so the UI can display them.
            await MainActor.run {
                withAnimation {
                    self.plannerListContext = PlannerListContext(
                        structuredDatestamps: searchResults,
                        query: query
                    )
                }
            }

            // Sync the result planners.

            let planners = modelContext.getBulkPlanners(
                for: Set(searchResults.datestamps)
            )

            syncPlanners(planners)
        }
    }

    func reloadPlannerList() {
        loadPlannerList(matching: plannerListContext.query)
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
                todayStartOfDay: todayService.todayStartOfDay,
                syncPast: forceSyncRoutineDatestamps.contains(datestamp),
                ekEventStore: calendarService.ekEventStore
            )

            forceSyncRoutineDatestamps.remove(datestamp)
        }

        // Sync weather for the planners coming up this week.
        if planner.datestamp.isNext7Days(todaystamp: todayService.todaystamp),
            let location = planner.location(
                settings: settings
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
        syncPlanners(planners)
    }

    func syncPlanners(_ planners: [Planner]) {
        for planner in planners {
            syncPlanner(planner)
        }
    }

    // MARK: - Refresh (invalidate and sync)

    func refresh() {
        invalidateRoutines()
        invalidateCalendar()
        invalidateWeather()
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
}
