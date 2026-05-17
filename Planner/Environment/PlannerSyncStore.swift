//
//  PlannerSyncStore.swift
//  Planner
//
//  Created by Alex Green on 4/14/26.
//

import Combine
import EventKit
import SwiftData
import SwiftDate
import SwiftUI

@MainActor
class PlannerSyncStore: ObservableObject {
    @Published private(set) var rebuildTrigger: UUID? = nil

    @Published var freshCalendarMap: [String: CalendarDayData] = [:]

    /// Datestamps that have loaded for each weekday.
    @Published private(set) var freshRoutineMap: [Weekday: Set<String>] =
        PlannerSyncStore.makeDefaultRoutineMap()

    private var inFlight: [String: Task<CalendarDayData, Never>] = [:]

    func beginRebuild() {
        rebuildTrigger = UUID()
    }

    func syncPlanner(
        _ planner: Planner,
        weekday: Weekday,
        plannerDay: DateInRegion,
        sortedPlannerEvents: [PlannerEvent],
        settings: PlannerSettings,
        ekEventStore: EKEventStore,
        todaystamp: String,
        modelContext: ModelContext
    ) -> Task<CalendarDayData, Never> {
        let syncRoutine = !(freshRoutineMap[weekday] ?? []).contains(
            planner.datestamp
        )

        if syncRoutine {
            modelContext.syncRoutine(
                for: planner,
                storageEvents: sortedPlannerEvents,
                plannerDay: plannerDay,
                weekday: weekday,
                ekEventStore: ekEventStore,
                todaystamp: todaystamp
            )

            freshRoutineMap[weekday]?.insert(planner.datestamp)
        }

        if let cachedCalendarData = freshCalendarMap[planner.key] {
            return Task { cachedCalendarData }
        }

        if let inFlight = inFlight[planner.key] {
            return inFlight
        }

        let task = Task {
            let calendarData = modelContext.syncCalendar(
                for: planner,
                storageEvents: sortedPlannerEvents,
                plannerDay: plannerDay,
                hiddenCalendarIds: settings.hiddenCalendarIds,
                ekEventStore: ekEventStore
            )

            await MainActor.run {
                freshCalendarMap[planner.key] = calendarData
                inFlight.removeValue(forKey: planner.key)
            }

            return calendarData
        }

        inFlight[planner.key] = task
        return task
    }

    func invalidateRoutineDays(_ weekdays: Set<Weekday>) {
        for weekday in weekdays {
            freshRoutineMap[weekday]?.removeAll()
        }
    }

    func invalidateCalendarDays(_ keys: Set<String>) {
        for key in keys {
            freshCalendarMap.removeValue(forKey: key)
        }
    }

    func invalidateCalendar() {
        freshCalendarMap.removeAll()
    }

    func invalidateDatestampRoutine(_ datestamp: String) {
        guard let weekday = Weekday.forDatestamp(datestamp) else {
            return
        }

        freshRoutineMap[weekday]?.remove(datestamp)
    }

    /// Re-syncs a single datestamp's routine.
    func rebuildDatestampRoutine(_ datestamp: String) {
        invalidateDatestampRoutine(datestamp)
        beginRebuild()
    }

    func rebuildCalendarData() {
        invalidateCalendar()
        beginRebuild()
    }

    func rebuildAllData() {
        freshCalendarMap.removeAll()
        freshRoutineMap = Self.makeDefaultRoutineMap()
        beginRebuild()
    }

    // MARK: - Helpers

    static func makeDefaultRoutineMap() -> [Weekday: Set<String>] {
        [
            .Friday: [],
            .Saturday: [],
            .Sunday: [],
            .Monday: [],
            .Tuesday: [],
            .Wednesday: [],
            .Thursday: [],
        ]
    }
}
