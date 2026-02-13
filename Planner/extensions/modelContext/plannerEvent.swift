//
//  plannerEvent.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import SwiftData
import SwiftDate
import SwiftUI

extension ModelContext {
    
    @MainActor
    func transferPlannerEvents(
        _ events: [PlannerEvent],
        into planner: Planner
    ) {

        planner.inheritEvents(events)

        do {
            try save()
        } catch {
            assertionFailure(
                "Failed to transfer events: \(error)"
            )
        }
    }

    @MainActor
    func deletePlannerEvents(
        _ events: [PlannerEvent]
    ) {

        for event in events {
            delete(event)
        }

        do {
            try save()
        } catch {
            assertionFailure(
                "Failed to delete plan: \(error)"
            )
        }
    }
    
}
