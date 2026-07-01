//
//  deletePlannerEvent.swift
//  Planner
//
//  Created by Alex Green on 6/15/26.
//

import EventKit
import SwiftData

extension ModelContext {
    @MainActor
    func deletePlannerEvent(
        _ plannerEvent: PlannerEvent,
        /// Deletes calendar events, otherwise they are preserved.
        ekEventStore: EKEventStore? = nil,
        skipSave: Bool = false
    ) {
        if let ekEventStore,
            plannerEvent.eKEventContext != nil,
            let ekEvent = ekEventStore.getEkEvent(for: plannerEvent),
            !ekEventStore.attemptDeleteEvent(ekEvent)
        {
            return
        }

        delete(plannerEvent)

        guard !skipSave else { return }

        safeSave("deletePlannerEvent")
    }
}
