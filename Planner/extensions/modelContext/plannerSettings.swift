//
//  plannerSettings.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

// Clean

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

        self.safeSave("plannerSettings.ensurePlannerSettings")
    }

    @MainActor
    func updateHomeLocation(
        in settings: PlannerSettings,
        to location: Location?
    ) {

        settings.homeLocation = location

        self.safeSave("plannerSettings.updateHomeLocation")
    }

    @MainActor
    func deleteStaleCalendarEvents(
        in settings: PlannerSettings,
        with eventIds: Set<String>
    ) {

        // TODO: implement

        // Sepcial case: do NOT save the context here. This will be done in the parent
        // function that called this.
    }

}
