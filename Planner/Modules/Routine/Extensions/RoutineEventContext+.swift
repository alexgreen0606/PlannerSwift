//
//  RoutineEventContext+.swift
//  Planner
//
//  Created by Alex Green on 4/7/26.
//

import SwiftDate
import SwiftUI

extension RoutineEventContext {

    var safeRoutineEvents: [RoutineEvent] {
        routineEvents ?? []
    }

    var weekdays: Set<Weekday> {
        Set(
            safeRoutineEvents.compactMap { routineEvent in
                guard let routine = routineEvent.routine else {
                    return nil
                }
                
                return Weekday(rawValue: routine.weekdayRawValue)
            }
        )
    }

    func routineEvent(for routine: Routine) -> RoutineEvent? {
        safeRoutineEvents.first(where: {
            $0.routine === routine
        })
    }

    func date(on startOfDay: DateInRegion) -> Date? {
        guard let time else {
            return nil
        }

        let utcTime = DateInRegion(time, region: .UTC)

        let dateInRegion = DateInRegion(
            year: startOfDay.year,
            month: startOfDay.month,
            day: startOfDay.day,
            hour: utcTime.hour,
            minute: utcTime.minute,
            second: 0,
            region: startOfDay.region
        )

        return dateInRegion.date
    }
    
    // MARK: - Synchronization
    
    func syncWithDraftRoutineEvent(
        _ draft: DraftRoutineEvent
    ) {
        title = draft.title.trimmed
        time = draft.hasTime ? draft.date : nil
        version += 0.1
    }
}
