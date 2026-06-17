//
//  handleRoutineEventTitleChange.swift
//  Planner
//
//  Created by Alex Green on 6/15/26.
//

import SwiftData

extension ModelContext {
    @MainActor
    func handleRoutineEventTitleChange(
        _ routineEvent: RoutineEvent
    ) {
        guard routineEvent.time == nil, let baseDay = Self.baseRoutineDate
        else {
            return
        }

        // Scan the title for a date.
        guard
            let (date, updatedText) = routineEvent.title.extractTime(
                for: baseDay
            )
        else {
            return
        }

        routineEvent.title = updatedText
        routineEvent.time = date

        safeSave("handleRoutineEventTitleChange")
    }
}
