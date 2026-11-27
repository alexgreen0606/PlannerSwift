//
//  PlannerEvent+.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import Foundation
import SwiftDate

extension PlannerEvent: PlannerEventLocationHelpers {
    static let gregorianCalendar = Calendar(identifier: .gregorian)

    static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    // MARK: - Synchronization

    @MainActor
    func syncWithRoutineEvent(on startOfDay: DateInRegion) {
        guard
            let routineEventRecordContext,
            !routineEventRecordContext.isVariant,
            let routineEventContext = routineEventRecordContext.routineEvent?
                .routineEventContext,
            routineEventRecordContext.syncedVersion
                != routineEventContext.version
        else {
            return
        }

        title = routineEventContext.title
        notes = routineEventContext.notes
        time = routineEventContext.date(on: startOfDay)

        routineEventRecordContext.syncedVersion = routineEventContext.version

        syncDraft()
    }

    @MainActor
    func updateRoutineVariance(
        in timeZone: TimeZone,
        settings: Settings
    ) {
        guard let routineEventRecordContext,
            let routineEventContext = routineEventRecordContext.routineEvent?
                .routineEventContext
        else {
            return
        }

        routineEventRecordContext.isVariant = !matches(
            routineEventContext,
            in: timeZone,
            settings: settings
        )
    }

    func matches(
        _ routineEvent: RoutineEventContext,
        in timeZone: TimeZone,
        settings: Settings
    ) -> Bool {
        guard eKEventContext == nil,
            location == nil,
            let originPlanner = routineEventRecordContext?.planner
        else {
            return false
        }

        // Title match.
        if title.trimmed != routineEvent.title.trimmed {
            return false
        }

        // Origin planner match.
        if let time {
            let originStartOfDay = originPlanner.startOfDay(settings: settings)

            if !time.belongsToPlanner(startOfDay: originStartOfDay) {
                return false
            }

        } else if datestamp != originPlanner.datestamp {
            return false
        }

        // Time match.

        var plannerCalendar = Self.gregorianCalendar
        plannerCalendar.timeZone = timeZone

        let eventComponents: DateComponents? = {
            guard let time else {
                return nil
            }

            return plannerCalendar.dateComponents(
                [.hour, .minute],
                from: time
            )
        }()

        let routineComponents: DateComponents? = {
            guard let routineEventTime = routineEvent.time else {
                return nil
            }

            return Self.utcCalendar.dateComponents(
                [.hour, .minute],
                from: routineEventTime
            )
        }()

        return eventComponents?.hour == routineComponents?.hour
            && eventComponents?.minute == routineComponents?.minute
    }
}
