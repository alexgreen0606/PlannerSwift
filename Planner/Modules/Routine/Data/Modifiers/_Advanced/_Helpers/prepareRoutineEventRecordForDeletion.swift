//
//  prepareRoutineEventRecordForDeletion.swift
//  Planner
//
//  Created by Alex Green on 6/16/26.
//

import EventKit
import SwiftData
import SwiftDate

extension ModelContext {
    /// Removes relationships of past planner events so they are not cascade-deleted.
    @MainActor
    func prepareRoutineEventRecordForDeletion(
        _ routineEventRecord: PlannerEvent,
        /// The first planner day where events should be deleted (and all days afterward).
        cutoffDay: DateInRegion,
        /// Collects calendar event external IDs that must be deleted from the calendar.
        externalCalendarIds: inout Set<String>
    ) -> PlannerEvent? {

        if let ekEventContext = routineEventRecord.eKEventContext {

            // Mark calendar events for present/future deletion.
            externalCalendarIds.insert(
                ekEventContext.calendarItemExternalIdentifier
            )

            if ekEventContext.endDate <= cutoffDay.date {
                // Event is from the past. Remove relationship to protect it.
                routineEventRecord.routineEventRecordContext?.plannerEvent = nil
                routineEventRecord.routineEventRecordContext = nil
                return nil
            }

        } else if let time = routineEventRecord.time {

            if time < cutoffDay.date {
                // Event is from the past. Remove relationship to protect it.
                routineEventRecord.routineEventRecordContext?.plannerEvent = nil
                routineEventRecord.routineEventRecordContext = nil
                return nil
            }

        } else if let datestamp = routineEventRecord.datestamp {

            if datestamp < cutoffDay.datestamp {
                // Event is from the past. Remove relationship to protect it.
                routineEventRecord.routineEventRecordContext?.plannerEvent = nil
                routineEventRecord.routineEventRecordContext = nil
                return nil
            }

        }

        return routineEventRecord
    }
}
