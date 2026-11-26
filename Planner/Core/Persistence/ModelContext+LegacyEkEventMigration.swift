//
//  ModelContext+LegacyEkEventMigration.swift
//  Planner
//
//  Created by Alex Green on 11/25/26.
//

import EventKit
import SwiftData

extension ModelContext {
    /// Converts legacy calendar-backed `PlannerEvent`s (those with an `EKEventContext`) into
    /// `EkEventPlannerState`s, carrying over their `sortDate` and `isCompleted`, then deletes them.
    ///
    /// Idempotent: once no legacy events remain, this is a single empty fetch. It is intentionally
    /// run on every launch rather than gated behind a flag, because CloudKit can deliver legacy
    /// records after the first run (fresh installs, or devices still running an older build).
    ///
    /// Remove along with `EKEventContext` once every device has migrated.
    @MainActor
    func migrateLegacyEkEventPlannerEvents(ekEventStore: EKEventStore) {
        // Reading events requires full access. Without it, leave the legacy data for a later launch.
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess
        else { return }

        let legacyEvents: [PlannerEvent]
        do {
            legacyEvents = try fetch(
                FetchDescriptor<PlannerEvent>(
                    predicate: #Predicate { $0.eKEventContext != nil }
                )
            )
        } catch {
            assertionFailure(
                "ERROR ModelContext+LegacyEkEventMigration migrateLegacyEkEventPlannerEvents \(error)"
            )
            return
        }

        guard !legacyEvents.isEmpty else { return }

        for plannerEvent in legacyEvents {
            guard let context = plannerEvent.eKEventContext else { continue }

            // If the event no longer exists in the calendar, the legacy record is simply dropped.
            if let ekEvent = findEkEvent(for: context, in: ekEventStore) {
                let state = ensureEkEventPlannerState(
                    for: ekEvent,
                    sortDate: plannerEvent.sortDate
                )

                // The legacy record is the source of truth for state created before this ran.
                state.sortDate = plannerEvent.sortDate
                state.isCompleted = plannerEvent.isCompleted
            }

            // Note: Cascades to the EKEventContext.
            delete(plannerEvent)
        }

        safeSave(
            "ModelContext+LegacyEkEventMigration migrateLegacyEkEventPlannerEvents"
        )
    }

    // MARK: - Helpers

    /// Finds the calendar occurrence that a legacy context pointed to.
    ///
    /// The context only stored the external identifier and the occurrence's start date, so the
    /// occurrence is located by searching around that date. This yields the real `occurrenceDate`,
    /// which differs from the start date for recurring occurrences that were moved.
    private func findEkEvent(
        for context: EKEventContext,
        in ekEventStore: EKEventStore
    ) -> EKEvent? {
        let externalIdentifier = context.calendarItemExternalIdentifier
        guard !externalIdentifier.isEmpty else { return nil }

        let padding: TimeInterval = 60 * 60 * 24
        let predicate = ekEventStore.predicateForEvents(
            withStart: context.startDate.addingTimeInterval(-padding),
            end: max(context.endDate, context.startDate)
                .addingTimeInterval(padding),
            calendars: nil
        )

        let candidates = ekEventStore.events(matching: predicate).filter {
            $0.calendarItemExternalIdentifier == externalIdentifier
        }

        // Prefer the exact occurrence; otherwise the one closest to the stored start date.
        return candidates.min {
            abs($0.startDate.timeIntervalSince(context.startDate))
                < abs($1.startDate.timeIntervalSince(context.startDate))
        }
    }
}
