//
//  EKEventStore+.swift
//  Planner
//
//  Created by Alex Green on 3/3/26.
//

import EventKit

extension EKEventStore {
    func getEkEvent(for plannerEvent: PlannerEvent) -> EKEvent? {
        guard let eKEventContext = plannerEvent.eKEventContext
        else {
            return nil
        }

        if let existing = eKEventContext.ekEvent {
            return existing
        }

        let startDate = eKEventContext.startDate
        let calendarItemExternalIdentifier = eKEventContext
            .calendarItemExternalIdentifier

        let ekEvent = getEkEvent(
            identifier: calendarItemExternalIdentifier,
            startDate: startDate
        )

        eKEventContext.ekEvent = ekEvent

        return ekEvent
    }

    func getEkEvent(identifier: String, startDate: Date) -> EKEvent? {
        return events(
            matching: predicateForEvents(
                withStart: startDate,
                end: startDate.addingTimeInterval(60),
                calendars: nil
            )
        ).first {
            $0.calendarItemExternalIdentifier == identifier
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
                "ERROR EKEventStore+ attemptUpdateEvent: \(error)"
            )
            return false
        }

        return true
    }

    func attemptDeleteEvent(_ event: EKEvent, span: EKSpan = .thisEvent)
        -> /// Returns the success of the deletion attempt.
        Bool
    {
        guard event.calendar.allowsContentModifications else {
            return false
        }

        do {
            try remove(
                event,
                span: span,
                commit: true
            )
        } catch {
            assertionFailure(
                "ERROR EKEventStore+ attemptDeleteEvent: \(error)"
            )
            return false
        }

        return true
    }

    func attemptDeleteEvents(
        externalIdentifiers: Set<String>,
        onOrAfter: Date
    )
        -> /// Returns the identifiers of the events that were successfully deleted.
        Set<String>
    {
        guard
            let endDate = Calendar.current.date(
                byAdding: .year,
                value: 3,
                to: onOrAfter
            )
        else {
            return []
        }

        let allEvents = events(
            matching: predicateForEvents(
                withStart: onOrAfter,
                end: endDate,
                calendars: nil
            )
        )

        var earliestEvents: [String: EKEvent] = [:]
        var deletedIdentifiers: Set<String> = []

        for ekEvent in allEvents {
            guard
                let externalIdentifier = ekEvent
                    .calendarItemExternalIdentifier,
                externalIdentifiers.contains(
                    ekEvent.calendarItemExternalIdentifier
                )
            else {
                continue
            }

            if let existing = earliestEvents[externalIdentifier] {
                if ekEvent.startDate < existing.startDate {
                    earliestEvents[externalIdentifier] = ekEvent
                }
            } else {
                earliestEvents[externalIdentifier] = ekEvent
            }
        }

        for ekEvent in earliestEvents.values {
            if attemptDeleteEvent(ekEvent, span: .futureEvents) {
                deletedIdentifiers.insert(
                    ekEvent.calendarItemExternalIdentifier
                )
            }
        }

        return deletedIdentifiers
    }
}
