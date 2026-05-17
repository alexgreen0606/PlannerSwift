//
//  EKEventStoreExtension.swift
//  Planner
//
//  Created by Alex Green on 3/3/26.
//

import EventKit

extension EKEventStore {
    // Returns the success of the update attempt.
    func attemptUpdateEvent(_ event: EKEvent) -> Bool {
        guard event.calendar.allowsContentModifications else {
            return false
        }

        do {
            try save(
                event,
                span: .thisEvent
            )
        } catch {
            assertionFailure(
                "ERROR EKEventStoreExtension.attemptUpdateEvent: \(error)"
            )
            return false
        }

        return true
    }

    // Returns the success of the deletion attempt.
    func attemptDeleteEvent(_ event: EKEvent) -> Bool {
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
            assertionFailure(
                "ERROR EKEventStoreExtension.attemptDeleteEvent: \(error)"
            )
        }

        return false
    }

    // TODO: what if this deletes every occurrence of a recurring event?
    func deleteEvent(identifier: String) {
        let items = calendarItems(withExternalIdentifier: identifier)

        for case let event as EKEvent in items {
            do {
                try remove(event, span: .thisEvent, commit: true)
            } catch {
                assertionFailure(
                    "ERROR EKEventStoreExtension.deleteEvent: \(error)"
                )
            }
        }
    }
}
