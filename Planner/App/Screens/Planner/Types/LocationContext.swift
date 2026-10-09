//
//  LocationContext.swift
//  Planner
//
//  Created by Alex Green on 7/29/26.
//

import Foundation

struct LocationContext: Identifiable {
    var location: Location?
    var types: [LocationType] = []

    var id: String { location.coordinateId }

    var timeZoneId: String {
        location?.timeZoneIdentifier ?? TimeZone.current.identifier
    }

    func locationName(deviceLocationName: String) -> String {
        location?.name ?? deviceLocationName
    }
}
