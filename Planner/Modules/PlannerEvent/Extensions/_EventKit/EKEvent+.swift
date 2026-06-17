//
//  EKEvent+.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import SwiftDate

extension EKEvent {
    func location(
        existingPlannerEvent: PlannerEvent? = nil
    ) -> Location? {
        if let locationLabel = location,
            let structuredLocation,
            let latitude = structuredLocation.geoLocation?.coordinate
                .latitude,
            let longitude = structuredLocation.geoLocation?.coordinate
                .longitude,
            let timeZone = timeZone
        {
            let newLocation = Location(
                name: locationLabel,
                latitude: latitude,
                longitude: longitude,
                timeZoneIdentifier: timeZone.identifier
            )

            guard let existingLocation = existingPlannerEvent?.location,
                existingLocation.coordinateId == newLocation.coordinateId
            else {
                return newLocation
            }

            // Location in storage matches the event's location. Continue using it.
            return existingLocation
        }

        return nil
    }
}
