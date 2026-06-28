//
//  nonCalendarRecords.swift
//  Planner
//
//  Created by Alex Green on 6/28/26.
//

import SwiftDate
import SwiftUI

extension PlannerEvent {
    static var nonCalendarRecords: Predicate<PlannerEvent> =
        #Predicate<PlannerEvent> {
            $0.eKEventContext == nil
        }
}
