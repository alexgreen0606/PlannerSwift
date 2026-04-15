//
//  PlannerBuildManager.swift
//  Planner
//
//  Created by Alex Green on 4/14/26.
//

import Combine
import SwiftUI

struct PlannerBuildConfig {
    var cachedCalendarData: CalendarDayData? = nil
    var syncRoutine: Bool = false
}

// Clean

@MainActor
class PlannerBuildManager: ObservableObject {

    @Published private(set) var rebuildTrigger: UUID? = nil

    @Published private(set) var freshCalendarMap: [String: CalendarDayData] =
        [:]

    // Datestamps that have loaded for each weekday.
    @Published private(set) var freshRoutineMap: [Weekday: Set<String>] =
        PlannerBuildManager.makeDefaultRoutineMap()

    func beginRebuild() {
        rebuildTrigger = UUID()
    }

    func cacheCalendarData(_ data: CalendarDayData, plannerKey: String) {
        freshCalendarMap[plannerKey] = data
    }

    func buildConfig(for planner: Planner) -> PlannerBuildConfig {
        var buildConfig = PlannerBuildConfig()

        guard let weekday = Weekday.from(planner.datestamp.weekday) else {
            return buildConfig
        }

        buildConfig.cachedCalendarData = freshCalendarMap[planner.key]
        buildConfig.syncRoutine = !(freshRoutineMap[weekday] ?? []).contains(
            planner.datestamp
        )

        return buildConfig
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

    func rebuildCalendarData() {
        freshCalendarMap.removeAll()
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
            .friday: [],
            .saturday: [],
            .sunday: [],
            .monday: [],
            .tuesday: [],
            .wednesday: [],
            .thursday: [],
        ]
    }

}
