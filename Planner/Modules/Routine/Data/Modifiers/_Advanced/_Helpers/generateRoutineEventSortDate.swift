//
//  generateRoutineEventSortDate.swift
//  Planner
//
//  Created by Alex Green on 6/16/26.
//

import EventKit
import SwiftData
import SwiftDate

extension ModelContext {
    @MainActor
    func generateRoutineEventSortDate(
        at index: Int,
        /// May or may not contain the routine event being placed.
        in sortedRoutineEventContexts: [RoutineEventContext],
        for routine: Routine
    ) -> Date {
        guard let baseDay = Self.baseRoutineDate else {
            // Fallback to now. This should never occur.
            return Date()
        }

        // TODO: should this just be a list of instances?
        return generateSortDate(
            at: index,
            in: sortedRoutineEventContexts,
            startOfDay: baseDay,
            routine: routine
        )
    }
}
