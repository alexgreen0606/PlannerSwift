//
//  settings.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

extension ModelContext {

    @MainActor
    func ensurePlannerSettings(
        settings: [PlannerSettings]
    ) {
        if settings.first != nil {
            return
        }

        let newSettings = PlannerSettings()
        insert(newSettings)

        do {
            try save()
        } catch {
            assertionFailure(
                "Failed to create initial PlannerSettings: \(error)"
            )
        }
    }

    @MainActor
    func updateHomeLocation(
        in settings: PlannerSettings,
        to location: Location?
    ) {

        settings.homeLocation = location

        do {
            try save()
        } catch {
            assertionFailure(
                "ERROR plannerSettings.updateHomeLocation: \(error)"
            )
        }
    }

    @MainActor
    func deleteStaleCalendarEventPositions(
        in settings: PlannerSettings,
        with eventIds: Set<String>
    ) {

        // TODO: implement

        // Sepcial case: do NOT save the context here. This will be done in the parent
        // function that called this.
    }

}
