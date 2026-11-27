//
//  calendarRecords.swift
//  Planner
//
//  Created by Alex Green on 6/15/26.
//

import SwiftDate
import SwiftUI

extension PlannerEvent {
    static func calendarRecords(
        for calendarItemExternalIdentifiers: Set<String>,
        onOrAfter cutoffDate: Date
    ) -> Predicate<PlannerEvent> {
        return #Predicate<PlannerEvent> { event in
            if let eKEventContext = event.eKEventContext {
                return calendarItemExternalIdentifiers.contains(
                    eKEventContext.calendarItemExternalIdentifier
                ) && eKEventContext.endDate >= cutoffDate
            } else {
                return false
            }
        }
    }
}
