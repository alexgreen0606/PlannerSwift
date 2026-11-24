//
//  EKEvent+.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import EventKit
import SwiftUI

/// Mirrors the calendar UI helpers on `PlannerEvent`, reading directly from the `EKEvent`.
extension EKEvent {
    func calendarColor(accentColor: AccentColor) -> Color {
        if let cgColor = calendar?.cgColor {
            return Color(cgColor: cgColor)
        }

        // Fallback to accent color.
        return accentColor.swiftUiColor
    }

    func calendarSystemImageName(settings: Settings) -> String {
        guard let calendarIdentifier = calendar?.calendarIdentifier else {
            return "calendar"
        }

        return settings.calendarIconMap[calendarIdentifier] ?? "calendar"
    }

    // TODO: remove existingPlannerEvent. It isn't needed.
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
