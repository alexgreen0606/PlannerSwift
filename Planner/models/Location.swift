//
//  Location.swift
//  Planner
//
//  Created by Alex Green on 2/5/26.
//

import SwiftData
import SwiftUI

// Clean

@Model
class Location {
    var name: String
    var subtitle: String?
    var latitude: Double
    var longitude: Double
    var timeZoneIdentifier: String
    
    // Used for displaying recents in LocationSearchForm.
    var selectedOn: Date

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
        self.selectedOn = .now
    }
    
}
