//
//  prepareRoutineEventRecordForDeletion.swift
//  Planner
//
//  Created by Alex Green on 6/16/26.
//

import EventKit
import SwiftData

extension ModelContext {
    // Note: This function filters out planner events that should be protected from deletion,
    // while also deleting linked calendar events.
    @MainActor
    func prepareRoutineEventRecordForDeletion(
        _ routineEventRecord: PlannerEvent,
        staleCalendarItemExternalIdentifiers: inout Set<String>,
        ekEventStore: EKEventStore
    ) -> PlannerEvent? {
        // MARK: Remove completed planner events so they are not cascade-deleted.
        if routineEventRecord.isCompleted {
            routineEventRecord.routineEventRecordContext?.plannerEvent = nil
            routineEventRecord.routineEventRecordContext = nil
            return nil
        }

        // TODO: make sure today or past all-day events are marked as isCompleted
        // so they are not deleted here

        // MARK: Delete calendar records.
        if let ekEventContext = routineEventRecord.eKEventContext {
            let identifier = ekEventContext.calendarItemExternalIdentifier

            _ = ekEventStore.attemptDeleteEvent(identifier: identifier)
            staleCalendarItemExternalIdentifiers.insert(identifier)
        }

        return routineEventRecord
    }
}
