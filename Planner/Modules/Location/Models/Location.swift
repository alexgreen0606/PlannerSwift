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

    // MARK: Sibling
    @Relationship(inverse: \Settings.homeLocation)
    var settings: Settings?

    // MARK: Sibling
    @Relationship(inverse: \Trip.location)
    var trips: [Trip]?

    // MARK: Sibling
    @Relationship(inverse: \Planner.location)
    var planners: [Planner]?

    // MARK: Sibling
    @Relationship(inverse: \PlannerEvent.location)
    var plannerEvents: [PlannerEvent]?

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
