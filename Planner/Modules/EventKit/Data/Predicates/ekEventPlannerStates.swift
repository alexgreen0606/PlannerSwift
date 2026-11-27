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

    /// Matches the states for exactly the given calendar event occurrences.
    ///
    /// Each event contributes its own (identifier, occurrence date) predicate, and the predicates are
    /// OR'd together as a balanced tree to keep the expression depth logarithmic in the event count.
    static func matching(
        ekEvents: [EKEvent]
    ) -> Predicate<EkEventPlannerState> {
        let predicates: [Predicate<EkEventPlannerState>] = ekEvents.compactMap {
            ekEvent in
            guard
                let externalIdentifier = ekEvent.calendarItemExternalIdentifier
            else {
                return nil
            }

            return matching(
                externalIdentifier: externalIdentifier,
                occurrenceDate: ekEvent.occurrenceDate
            )
        }

        return anyOf(predicates[...])
    }

    /// Matches every state belonging to the given calendar event identifiers (any occurrence).
    /// Note: Cheaper than `matching(ekEvents:)` for large sets. Match occurrences in memory.
    static func matching(
        externalIdentifiers: [String]
    ) -> Predicate<EkEventPlannerState> {
        #Predicate { state in
            externalIdentifiers.contains(state.externalIdentifier)
        }
    }

    // MARK: - Helpers

    private static func anyOf(
        _ predicates: ArraySlice<Predicate<EkEventPlannerState>>
    ) -> Predicate<EkEventPlannerState> {
        switch predicates.count {
        case 0:
            return #Predicate { _ in false }
        case 1:
            return predicates[predicates.startIndex]
        default:
            let middle = predicates.startIndex + predicates.count / 2
            let lhs = anyOf(predicates[..<middle])
            let rhs = anyOf(predicates[middle...])

            return #Predicate { state in
                lhs.evaluate(state) || rhs.evaluate(state)
            }
        }
    }
}
