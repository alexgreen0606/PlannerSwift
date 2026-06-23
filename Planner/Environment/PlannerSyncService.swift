//
//  PlannerSyncService.swift
//  Planner
//
//  Created by Alex Green on 4/14/26.
//

import Combine
import EventKit
import SwiftData
import SwiftDate

@MainActor
class PlannerSyncService: ObservableObject {
    @Published private(set) var syncTrigger: UUID?

    /// Planner keys that have up-to-date calendar data.
    @Published var freshCalendarPlannerKeys: Set<String> = []

    /// Weekdays mapped to all planner datestamps that have synced with their routines.
    @Published private(set) var freshRoutineMap: [Weekday: Set<String>] =
        [:]

    func beginSync() {
        syncTrigger = UUID()
    }

    func syncPlanner(
        _ planner: Planner,
        startOfDay: DateInRegion,
        todaystamp: String,
        ekEventStore: EKEventStore,
        modelContext: ModelContext,
        settings: PlannerSettings
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
            for: planner,
            startOfDay: startOfDay,
            ekEventStore: ekEventStore,
            settings: settings
        )
    }

    // MARK: - Manual Sync Functions

    func syncCalendar() {
        invalidateCalendar()
        beginSync()
    }

    func syncPlannerRoutine(datestamp: String) {
        invalidatePlannerRoutine(datestamp: datestamp)
        beginSync()
    }

    func syncAllPlanners() {
        invalidateCalendar()
        freshRoutineMap.removeAll()
        beginSync()
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
}
