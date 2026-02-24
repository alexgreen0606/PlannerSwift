//
//  DraftPlannerEvent.swift
//  Planner
//
//  Created by Alex Green on 2/24/26.
//

import SwiftUI
import EventKit
import SwiftDate

struct DraftPlannerEvent {
    var title: String = ""
    var date: Date = Date()
    var hasTime: Bool = false
    var locationSource: LocationSource = .current
    var location: Location? = nil
    var calendarEvent: EKEvent? = nil

    // Nil means the current device location is used.
    private func location(settings: PlannerSettings, planner: Planner?) -> Location? {
        eventLocation(locationSource: locationSource, location: location, planner: planner, settings: settings)
    }

    func region(settings: PlannerSettings, planner: Planner?) -> Region {
        location(settings: settings, planner: planner)?.region ?? .local
    }

    func locationLabel(
        localCityName: String,
        settings: PlannerSettings,
        planner: Planner?
    ) -> String {
        location(settings: settings, planner: planner)?.name ?? localCityName
    }
}
