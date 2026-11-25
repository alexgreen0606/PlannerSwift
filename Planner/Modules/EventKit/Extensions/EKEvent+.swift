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

    func location() -> Location? {
        if let locationLabel = location,
            let structuredLocation,
            let latitude = structuredLocation.geoLocation?.coordinate
                .latitude,
            let longitude = structuredLocation.geoLocation?.coordinate
                .longitude,
            let timeZone = timeZone
        {
            return Location(
                name: locationLabel,
                latitude: latitude,
                longitude: longitude,
                timeZoneIdentifier: timeZone.identifier
            )
        }

        return nil
    }
}
