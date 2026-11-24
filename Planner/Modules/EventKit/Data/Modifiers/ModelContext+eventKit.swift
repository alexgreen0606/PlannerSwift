//
//  ModelContext+.swift
//  Planner
//
//  Created by Alex Green on 11/23/26.
//

import EventKit
import SwiftData

extension ModelContext {
    // MARK: - ENSURE

    /// Returns the calendar event's Planner state, creating one if it doesn't exist yet.
    @MainActor
    func ensureEkEventPlannerState(
        for ekEvent: EKEvent,
        /// The state attached to the list item (may be stale or nil).
        existing: EkEventPlannerState? = nil,
        /// Used only when a new state must be created.
        sortDate: Date
    ) -> EkEventPlannerState {
        if let existing {
            return existing
        }

        if let stored = getEkEventPlannerState(for: ekEvent) {
            return stored
        }

        let newState = EkEventPlannerState(ekEvent: ekEvent, sortDate: sortDate)
        insert(newState)
        return newState
    }

    // MARK: - READ

    /// Fetches the persisted Planner state for a calendar event occurrence.
    /// Note: Pending (unsaved) inserts are included, which prevents duplicate states.
    func getEkEventPlannerState(for ekEvent: EKEvent) -> EkEventPlannerState? {
        guard let externalIdentifier = ekEvent.calendarItemExternalIdentifier
        else {
            return nil
        }

        let occurrenceDate: Date? = ekEvent.occurrenceDate

        var descriptor = FetchDescriptor<EkEventPlannerState>(
            predicate: EkEventPlannerState.matching(
                externalIdentifier: externalIdentifier,
                occurrenceDate: occurrenceDate
            )
        )

        descriptor.fetchLimit = 1

        do {
            return try fetch(descriptor).first
        } catch {
            assertionFailure(
                "ERROR ModelContext+eventKit getEkEventPlannerState: \(error)"
            )
        }

        return nil
    }

    // MARK: - DELETE

    @MainActor
    func deleteEkEventPlannerState(
        for ekEvent: EKEvent,
        existing: EkEventPlannerState? = nil
    ) {
        if let state = existing ?? getEkEventPlannerState(for: ekEvent) {
            delete(state)
        }
    }
}
