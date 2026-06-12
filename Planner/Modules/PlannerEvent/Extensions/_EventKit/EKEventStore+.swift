//
//  EKEventStore+.swift
//  Planner
//
//  Created by Alex Green on 3/3/26.
//

import EventKit

extension EKEventStore {
    func loadCalendarEvent(for plannerEvent: PlannerEvent) -> EKEvent? {
        if let existing = plannerEvent.calendarContext?.ekEvent {
            return existing
        }
        
        guard let startDate = plannerEvent.calendarContext?.startDate else {
            return nil
        }

        let predicate = predicateForEvents(
            withStart: startDate,
            end: startDate.addingTimeInterval(60),
            calendars: nil
        )

        let calendarItemExternalIdentifier = plannerEvent.calendarContext?
            .calendarItemExternalIdentifier

        return events(matching: predicate).first {
            $0.calendarItemExternalIdentifier == calendarItemExternalIdentifier
        }
    }

    func attemptUpdateEvent(_ event: EKEvent)
        -> /// Returns the success of the update attempt.
        Bool
    {
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
                "ERROR EKEventStore+.attemptUpdateEvent: \(error)"
            )
            return false
        }

        return true
    }

    func attemptDeleteEvent(_ event: EKEvent)
        -> /// Returns the success of the deletion attempt.
        Bool
    {
        guard event.calendar.allowsContentModifications else {
            return false
        }

        do {
            try remove(
                event,
                span: .thisEvent,
                commit: true
            )
        } catch {
            assertionFailure(
                "ERROR EKEventStore+.attemptDeleteEvent: \(error)"
            )
            return false
        }

        return true
    }

    // TODO: what if this deletes every occurrence of a recurring event? Maybe I should pass a start date?
    func attemptDeleteEvent(identifier: String) -> Bool {
        let items = calendarItems(withExternalIdentifier: identifier)

        for case let event as EKEvent in items {
            do {
                try remove(event, span: .thisEvent, commit: true)
            } catch {
                assertionFailure(
                    "ERROR EKEventStore+.deleteEvent: \(error)"
                )
                return false
            }
        }

        return true
    }
}
