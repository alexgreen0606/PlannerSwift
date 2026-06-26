//
//  handleRoutineEventContextTitleChange.swift
//  Planner
//
//  Created by Alex Green on 6/15/26.
//

import SwiftData

extension ModelContext {
    @MainActor
    func handleRoutineEventContextTitleChange(
        _ routineEventContext: RoutineEventContext
    ) {
        guard routineEventContext.time == nil, let baseDay = Self.baseRoutineDate
        else {
            return
        }

        // Scan the title for a date.
        guard
            let (date, updatedText) = routineEventContext.title.extractTime(
                for: baseDay
            )
        else {
            return
        }

        routineEventContext.title = updatedText
        routineEventContext.time = date

        safeSave("handleRoutineEventContextTitleChange")
    }
}
