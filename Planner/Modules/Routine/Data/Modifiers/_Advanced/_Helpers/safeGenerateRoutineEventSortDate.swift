//
//  safeGenerateRoutineEventSortDate.swift
//  Planner
//
//  Created by Alex Green on 6/16/26.
//

import EventKit
import SwiftData
import SwiftDate

extension ModelContext {
    @MainActor
    func safeGenerateRoutineEventSortDate(
        at index: Int,
        /// May or may not contain the routine event being placed.
        in sortedRoutineEvents: [RoutineEvent],
        for routine: Routine
    ) -> Date {
        guard let baseDay = Self.baseRoutineDate else {
            // Fallback to now. This should never occur.
            return Date()
        }

        return generateRoutineEventSortDate(
            at: index,
            in: sortedRoutineEvents,
            startOfDay: baseDay,
            routine: routine
        )
    }
}
