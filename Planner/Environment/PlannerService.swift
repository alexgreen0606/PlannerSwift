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

struct PlannerSearchResults {
    let datestampMap: [String: [String]]
    let topDatestamp: String?
    let sortedYears: [String]
    let activeQuery: PlannerSearchQuery?

    init(
        datestampMap: [String: [String]] = [:],
        topDatestamp: String? = nil,
        sortedYears: [String] = [],
        activeQuery: PlannerSearchQuery? = nil
    ) {
        self.datestampMap = datestampMap
        self.topDatestamp = topDatestamp
        self.sortedYears = sortedYears
        self.activeQuery = activeQuery
    }
}

@MainActor
class PlannerService: ObservableObject {
    let modelContext: ModelContext
    let ekEventStore: EKEventStore
    let settings: PlannerSettings

    init(
        modelContext: ModelContext,
        ekEventStore: EKEventStore,
        settings: PlannerSettings
    ) {
        self.modelContext = modelContext
        self.ekEventStore = ekEventStore
        self.settings = settings

        self.plannerSearchService = PlannerSearchService(
            modelContainer: modelContext.container
        )
    }

    private var plannerSearchService: PlannerSearchService

    @Published private(set) var refreshTrigger: UUID = UUID()

    @Published private(set) var sortedUpcomingTrips: [Trip] = []

    @Published private(set) var searchResults = PlannerSearchResults()

    @Published private(set) var thisWeekDatestamps: [String] = []

    /// Planner keys that have up-to-date calendar data.
    @Published var freshCalendarPlannerKeys: Set<String> = []

    /// Weekdays mapped to all planner datestamps that have synced with their routines.
    @Published private(set) var freshRoutineMap: [Weekday: Set<String>] =
        [:]

    func syncPlanners(todaystamp: String) {
        var datestampsToSync: Set<String> = []
        var buildContexts: [PlannerBuildContext] = []

        // MARK: Gather trip datestamps for synchronization.

        sortedUpcomingTrips = modelContext.getSortedTrips(
            onOrBefore: todaystamp
        )

        for trip in sortedUpcomingTrips {
            for planner in trip.safePlanners {
                buildContexts.append(
                    PlannerBuildContext(
                        planner: planner,
                        startOfDay: planner.startOfDay(settings: settings)
                    )
                )
                datestampsToSync.insert(planner.datestamp)
            }
        }

        // MARK: Gather this week datestamps for synchronization.

        let today = DateInRegion(region: .local)

        thisWeekDatestamps = (0..<7).map { offset in
            today
                .dateByAdding(offset, .day)
                .toFormat("yyyy-MM-dd")
        }

        let newDatestampsToSync = Set(
            thisWeekDatestamps
        )
        .subtracting(datestampsToSync)

        if !newDatestampsToSync.isEmpty {
            buildContexts.append(
                contentsOf: modelContext.getBulkPlannerBuildContexts(
                    for: newDatestampsToSync,
                    settings: settings
                )
            )
            datestampsToSync.formUnion(newDatestampsToSync)
        }

        // MARK: Gather search result datestamps for synchronization.

        let todayPlanner = modelContext.getPlanner(
            for: todaystamp
        )

        search(
            with: PlannerSearchQuery(
                text: "",
                calendarIds: [],
                past: false,
                todayStartOfDay: todayPlanner.startOfDay(settings: settings),
                fuse: Fuse()
            ),
            todaystamp: todaystamp
        )

        // MARK: Sync all planners at once.

        for buildContext in buildContexts {
            syncPlanner(
                buildContext.planner,
                startOfDay: buildContext.startOfDay,
                todaystamp: todaystamp
            )
        }
    }

    func beginRefresh() {
        refreshTrigger = UUID()
    }

    func search(
        with query: PlannerSearchQuery,
        todaystamp: String
    ) {
        Task {
            let datestampMap = await plannerSearchService.search(
                query: query,
                ekEventStore: ekEventStore,
                settings: settings
            )

            guard !Task.isCancelled else { return }

            // Sync the result planners.

            let buildContexts = modelContext.getBulkPlannerBuildContexts(
                for: Set(datestampMap.values.flatMap { $0 }),
                settings: settings
            )

            for buildContext in buildContexts {
                syncPlanner(
                    buildContext.planner,
                    startOfDay: buildContext.startOfDay,
                    todaystamp: todaystamp
                )
            }

            // Return results so the UI can display them.
            await MainActor.run {
                let sortedKeys = datestampMap.keys.sorted {
                    query.past ? $0 > $1 : $0 < $1
                }

                let top = sortedKeys.first.flatMap { datestampMap[$0]?.first }

                self.searchResults = PlannerSearchResults(
                    datestampMap: datestampMap,
                    topDatestamp: top,
                    sortedYears: sortedKeys,
                    activeQuery: query
                )
            }
        }
    }

    func syncPlanner(
        _ planner: Planner,
        startOfDay: DateInRegion,
        todaystamp: String
    ) {
        guard
            let weekday = Weekday.forDatestamp(planner.datestamp)
        else {
            return
        }

        // MARK: Sync Routine

        let syncRoutine = !(freshRoutineMap[weekday] ?? []).contains(
            planner.datestamp
        )

        if syncRoutine {
            modelContext.syncRoutine(
                for: planner,
                startOfDay: startOfDay,
                todaystamp: todaystamp,
                ekEventStore: ekEventStore
            )

            freshRoutineMap[weekday, default: []].insert(planner.datestamp)
        }

        // MARK: Sync Calendar

        if freshCalendarPlannerKeys.contains(planner.plannerLocationId) {
            return
        }

        freshCalendarPlannerKeys.insert(planner.plannerLocationId)

        modelContext.syncCalendar(
            startOfDay: startOfDay,
            ekEventStore: ekEventStore,
            settings: settings
        )
    }

    // MARK: - Manual Sync Functions

    func syncCalendar() {
        invalidateCalendar()
        beginRefresh()
    }

    func syncPlannerRoutine(datestamp: String) {
        invalidatePlannerRoutine(datestamp: datestamp)
        beginRefresh()
    }

    func syncAllPlanners() {
        invalidateCalendar()
        freshRoutineMap.removeAll()
        beginRefresh()
    }

    // MARK: - Invalidation Functions

    func invalidateCalendar() {
        freshCalendarPlannerKeys.removeAll()
    }

    func invalidatePlannerRoutine(datestamp: String) {
        guard let weekday = Weekday.forDatestamp(datestamp) else {
            return
        }

        freshRoutineMap[weekday]?.remove(datestamp)
    }

    func invalidateRoutines(weekdays: Set<Weekday>) {
        for weekday in weekdays {
            freshRoutineMap[weekday]?.removeAll()
        }
    }

    // TODO: functions:

    // MARK: updateThisWeekDatestamps (with animation)

}
