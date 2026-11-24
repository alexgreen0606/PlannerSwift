//
//  EkEventPlannerState.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import EventKit
import Foundation
import SwiftData

@Model
final class EkEventPlannerState {
    var externalIdentifier: String = ""
    var recurrenceOccurrenceDate: Date?

    var sortDate: Date = Date.now
    var isCompleted: Bool = false

    init(
        ekEvent: EKEvent,
        /// This should always place the event at the top of its earliest planner.
        sortDate: Date
    ) {
        self.externalIdentifier = ekEvent.calendarItemExternalIdentifier
        self.recurrenceOccurrenceDate = ekEvent.occurrenceDate
        self.sortDate = sortDate
    }
}
