//
//  EkEventIdentity.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import EventKit
import Foundation

/// A stable identity for a calendar event occurrence.
struct EkEventIdentity: Hashable {
    let externalIdentifier: String
    let calendarIdentifier: String
    let recurrenceOccurrenceDate: Date?

    init?(ekEvent: EKEvent) {
        guard let externalIdentifier = ekEvent.calendarItemExternalIdentifier
        else {
            return nil
        }

        self.externalIdentifier = externalIdentifier
        self.calendarIdentifier = ekEvent.calendar.calendarIdentifier
        self.recurrenceOccurrenceDate = ekEvent.occurrenceDate
    }
}
