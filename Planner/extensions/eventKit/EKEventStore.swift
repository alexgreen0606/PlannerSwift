//
//  EKEventStore.swift
//  Planner
//
//  Created by Alex Green on 3/3/26.
//

import EventKit

extension EKEventStore {

    func deleteEvent(_ event: EKEvent) {
        guard event.calendar.allowsContentModifications else {
            print("Cannot delete event. Calendar is read-only.")
            return
        }

        do {
            try remove(event, span: .thisEvent, commit: true)
        } catch {
            assertionFailure("ERROR EKEventStore.deleteEvent: \(error)")
        }
    }

}
