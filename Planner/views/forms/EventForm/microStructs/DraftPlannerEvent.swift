//
//  DraftPlannerEvent.swift
//  Planner
//
//  Created by Alex Green on 2/24/26.
//

import SwiftUI
import EventKit
import SwiftDate

// Clean

struct DraftPlannerEvent {
    var title: String = ""
    var date: Date = Date()
    var hasTime: Bool = false
    var location: Location? = nil
    var calendarEvent: EKEvent? = nil

    private func location(
        planner: Planner?,
        settings: PlannerSettings,
        deviceLocation: Location?
    )
        -> Location? // nil means the current device location is used
    {
        eventLocation(
            location: location,
            planner: planner,
            settings: settings,
            deviceLocation: deviceLocation
        )
    }

    func region(
        planner: Planner?,
        settings: PlannerSettings,
        deviceLocation: Location?
    ) -> Region {
        location(
            planner: planner,
            settings: settings,
            deviceLocation: deviceLocation
        )?.region ?? .local
    }

    func locationLabel(
        planner: Planner?,
        settings: PlannerSettings,
        deviceLocation: Location?
    ) -> String {
        location(
            planner: planner,
            settings: settings,
            deviceLocation: deviceLocation
        )?.name ?? "Current Location"
    }
    
}
