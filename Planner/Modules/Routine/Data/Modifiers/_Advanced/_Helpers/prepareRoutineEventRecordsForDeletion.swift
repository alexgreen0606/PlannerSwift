//
//  prepareRoutineEventRecordsForDeletion.swift
//  Planner
//
//  Created by Alex Green on 6/16/26.
//

import EventKit
import SwiftData

extension ModelContext {
    @MainActor
    func prepareRoutineEventRecordsForDeletion(
        _ routineEventRecords: [PlannerEvent],
        staleCalendarItemExternalIdentifiers: inout Set<String>,
        ekEventStore: EKEventStore
    ) -> [PlannerEvent] {
        routineEventRecords.compactMap { routineEventRecord in

            // MARK: Remove completed planner events so they are not cascade-deleted.
            if routineEventRecord.isCompleted {
                routineEventRecord.routineEvent = nil
                return nil
            }

            // MARK: Delete calendar records.
            if let ekEventContext = routineEventRecord.eKEventContext {
                let identifier = ekEventContext.calendarItemExternalIdentifier

                _ = ekEventStore.attemptDeleteEvent(identifier: identifier)
                staleCalendarItemExternalIdentifiers.insert(identifier)
            }

            return routineEventRecord
        }
    }
}
