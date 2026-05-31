//
//  Location.swift
//  Planner
//
//  Created by Alex Green on 2/5/26.
//

import SwiftData
import SwiftUI

@Model
class Location {
    var name: String = ""
    var subtitle: String?
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var timeZoneIdentifier: String = ""

    /// Used for displaying recents in LocationSearchForm.
    var selectedOn: Date = Date.now

    var plannerSettings: PlannerSettings?
    var trips: [Trip]?
    var planners: [Planner]?
    var events: [PlannerEvent]?

    init(
        name: String,
        subtitle: String? = nil,
        latitude: Double,
        longitude: Double,
        timeZoneIdentifier: String
    ) {
        self.name = name
        self.subtitle = subtitle
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneIdentifier = timeZoneIdentifier
    }
}
