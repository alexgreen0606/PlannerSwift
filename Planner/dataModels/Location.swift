//
//  Location.swift
//  Planner
//
//  Created by Alex Green on 2/5/26.
//

import SwiftData

@Model
class Location {
    var name: String
    var subtitle: String?
    var latitude: Double
    var longitude: Double
    
    init(name: String, subtitle: String? = nil, latitude: Double, longitude: Double) {
        self.name = name
        self.subtitle = subtitle
        self.latitude = latitude
        self.longitude = longitude
    }
}
