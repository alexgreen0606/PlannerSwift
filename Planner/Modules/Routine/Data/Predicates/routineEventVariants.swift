//
//  routineEventVariants.swift
//  Planner
//
//  Created by Alex Green on 6/15/26.
//

import SwiftUI

extension RoutineEventVariant {
    static func routineEventVariants(
        for calendarItemExternalIdentifier: String
    ) -> Predicate<RoutineEventVariant> {
        return #Predicate<RoutineEventVariant> {
            if let ekEventContext = $0.plannerEvent?.eKEventContext {
                return ekEventContext.calendarItemExternalIdentifier
                    == calendarItemExternalIdentifier
            } else {
                return false
            }
        }
    }
}
