//
//  EKEventStore.swift
//  Planner
//
//  Created by Alex Green on 3/3/26.
//

import EventKit

// Clean

extension EKEventStore {

    func updateEvent(_ event: EKEvent) -> Bool {
        guard event.calendar.allowsContentModifications else {
            return false
        }

        do {
            try self.save(
                event,
                span: .thisEvent
            )
        } catch {
            assertionFailure(
                "ERROR EKEventStore.updateEvent: \(error)"
            )
            return false
        }

        return true
    }

    func deleteEvent(_ event: EKEvent) -> Bool {
        guard event.calendar.allowsContentModifications else {
            return false
        }

        do {
            try remove(
                event,
                span: .thisEvent,
                commit: true
            )

            return true
        } catch {
            assertionFailure("ERROR EKEventStore.deleteEvent: \(error)")
        }

        return false
    }

    func deleteEvent(for identifier: String) {
        let items = self.calendarItems(withExternalIdentifier: identifier)

        for case let event as EKEvent in items {
            do {
                try self.remove(event, span: .thisEvent, commit: true)
            } catch {
                assertionFailure("ERROR EKEventStore.deleteEvent: \(error)")
            }
        }
    }

}
