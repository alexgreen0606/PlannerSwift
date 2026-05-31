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
    private var inFlightCalendarSync: [String: Task<CalendarDayData?, Never>] =
        [:]

    @Published private(set) var syncTrigger: UUID?

    /// Planner keys mapped to their calendar data.
    @Published var freshCalendarMap: [String: CalendarDayData] =
        [:]

    /// Weekdays mapped to all planner datestamps that have synced with their routines.
    @Published private(set) var freshRoutineMap: [Weekday: Set<String>] =
        [:]

    func beginSync() {
        syncTrigger = UUID()
    }

    func syncPlanner(
        _ planner: Planner,
        startOfDay: DateInRegion,
        sortedPlannerEvents: [PlannerEvent],
        todaystamp: String,
        ekEventStore: EKEventStore,
        modelContext: ModelContext,
        settings: PlannerSettings
    ) -> Task<CalendarDayData?, Never> {
        guard
            let weekday = Weekday.forDatestamp(planner.datestamp)
        else {
            return Task { nil }
        }

        // MARK: Sync Routine

        let syncRoutine = !(freshRoutineMap[weekday] ?? []).contains(
            planner.datestamp
        )

        if syncRoutine {
            modelContext.syncRoutine(
                for: planner,
                storageEvents: sortedPlannerEvents,
                startOfDay: startOfDay,
                weekday: weekday,
                ekEventStore: ekEventStore,
                todaystamp: todaystamp
            )

            freshRoutineMap[weekday, default: []].insert(planner.datestamp)
        }

        // MARK: Sync Calendar

        if let cachedCalendarData = freshCalendarMap[planner.plannerLocationId] {
            return Task { cachedCalendarData }
        }

        if let inFlight = inFlightCalendarSync[planner.plannerLocationId] {
            return inFlight
        }

        let task: Task<CalendarDayData?, Never> = Task {
            let calendarDayData = modelContext.syncCalendar(
                for: planner,
                storageEvents: sortedPlannerEvents,
                startOfDay: startOfDay,
                hiddenCalendarIds: settings.hiddenCalendarIds,
                ekEventStore: ekEventStore
            )

            await MainActor.run {
                freshCalendarMap[planner.plannerLocationId] = calendarDayData
                inFlightCalendarSync.removeValue(forKey: planner.plannerLocationId)
            }

            return calendarDayData
        }

        inFlightCalendarSync[planner.plannerLocationId] = task

        return task
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
        freshCalendarMap.removeAll()
        freshRoutineMap.removeAll()
        beginSync()
    }

    // MARK: - Invalidation Functions

    func invalidateCalendar() {
        freshCalendarMap.removeAll()
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
