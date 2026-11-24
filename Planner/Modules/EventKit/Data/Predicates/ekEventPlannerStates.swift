//
//  ekEventPlannerStates.swift
//  Planner
//
//  Created by Alex Green on 11/23/26.
//

import EventKit
import SwiftUI

extension EkEventPlannerState {
    static func matching(
        externalIdentifier: String,
        occurrenceDate: Date?
    ) -> Predicate<EkEventPlannerState> {
        #Predicate { state in
            state.externalIdentifier == externalIdentifier
                && state.recurrenceOccurrenceDate == occurrenceDate
        }
    }
}
