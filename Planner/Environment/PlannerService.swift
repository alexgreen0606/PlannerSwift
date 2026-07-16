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

        self.searchResults = SearchResults(
            activeQuery: modelContext.defaultSearchQuery(
                todaystamp: todayService.todaystamp,
                settings: settings
            )
        )
    }

    private var searchService: SearchService

    /// Planner location keys that have synced with the calendar.
    private var freshCalendarLocationKeys: Set<String> = []

    /// Panner datestamps that have synced with their routine.
    private var freshRoutineDatestamps: Set<String> = []

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

            let syncContexts = modelContext.getBulkPlannerSyncContexts(
                for: Set(datestampMap.values.flatMap { $0 }),
                settings: settings
            )

            for syncContext in syncContexts {
                syncPlanner(
                    syncContext.planner,
                    startOfDay: syncContext.startOfDay
                )
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
        let startOfDay = planner.startOfDay(settings: settings)
        syncPlanner(
            planner,
            startOfDay: startOfDay
        )
    }

    func syncPlanner(
        _ planner: Planner,
        startOfDay: DateInRegion
    ) {
        guard settings.homeLocation != nil
        else { return }
        
        let datestamp = planner.datestamp

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

        guard
            !calendarService.isOnboardingCalendars
        else { return }

        let locationKey = planner.locationKey

        // Sync calendar.
        if !freshCalendarLocationKeys.contains(locationKey) {
            freshCalendarLocationKeys.insert(locationKey)

            modelContext.syncCalendar(
                startOfDay: startOfDay,
                calendarService: calendarService,
                settings: settings
            )
        }
    }

    // MARK: - Bulk Synchronization

    func syncVisiblePlanners() {
        let syncContexts = modelContext.getBulkPlannerSyncContexts(
            for: visibleDatestamps,
            settings: settings
        )

        for syncContext in syncContexts {
            syncPlanner(
                syncContext.planner,
                startOfDay: syncContext.startOfDay
            )
        }
    }

    func refresh() {
        invalidateRoutines()
        invalidateCalendar()
        loadVisibleDatestamps()
        syncVisiblePlanners()
    }

    func syncVisiblePlannersCalendar() {
        invalidateCalendar()
        syncVisiblePlanners()
    }

    func syncVisiblePlannerRoutines() {
        invalidateRoutines()
        syncVisiblePlanners()
    }

    func syncPlannerRoutine(planner: Planner) {
        let datestamp = planner.datestamp

        freshRoutineDatestamps.remove(datestamp)
        forceSyncRoutineDatestamps.insert(datestamp)
        syncPlanner(
            planner,
            startOfDay: planner.startOfDay(settings: settings)
        )
    }

    // MARK: - Invalidation

    func invalidateRoutines() {
        freshRoutineDatestamps = []
    }

    func invalidateCalendar() {
        freshCalendarLocationKeys = []
    }

    // MARK: - Change Handlers

    func handleTripChange() {
        withAnimation {
            loadTrips()
        }

        syncVisiblePlannerRoutines()
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
