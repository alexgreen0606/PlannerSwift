//
//  RoutineEvent+.swift
//  Planner
//
//  Created by Alex Green on 4/7/26.
//

import SwiftDate
import SwiftUI

extension RoutineEvent {
    var safePlannerEvents: [PlannerEvent] {
        plannerEvents ?? []
    }

    var safeVariants: [RoutineEventVariant] {
        variants ?? []
    }

    var safeWeekdayInstances: [RoutineEventWeekdayInstance] {
        weekdayInstances ?? []
    }

    var weekdays: Set<Weekday> {
        Set(
            safeWeekdayInstances.compactMap {
                Weekday(rawValue: $0.weekdayRawValue)
            }
        )
    }

    func instance(on weekday: Weekday) -> RoutineEventWeekdayInstance? {
        safeWeekdayInstances.first(where: {
            $0.weekdayRawValue == weekday.rawValue
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
    }
}
