//
//  PlannerExtension.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import Fuse
import SwiftDate
import SwiftUI

// Clean

extension Planner {
    var key: String {
        let locationKey = location?.coordinateKey ?? "HOME_LOCATION"
        return "\(datestamp)-\(locationKey)"
    }

    var safeRoutineEventVariants: [RoutineEventVariant] {
        routineEventVariants ?? []
    }

    var safeExcludeRoutine: Bool {
        if let customExclusion = excludeRoutine {
            return customExclusion
        }
        return trip?.excludeRoutines ?? false
    }

    // MARK: - Location Variables

    func location(settings: PlannerSettings, deviceLocation: Location?)
        -> Location? // nil means the device location is used and hasn't loaded yet
    {
        location ?? trip?.location
            ?? settings.homeLocation(deviceLocation: deviceLocation)
    }

    func region(settings: PlannerSettings) -> Region {
        location?.region ?? settings.homeRegion
    }

    func locationLabel(settings: PlannerSettings, deviceLocation: Location?)
        -> String
    {
        location(settings: settings, deviceLocation: deviceLocation)?.name
            ?? "Current Location"
    }

    func locationIconConfig(settings: PlannerSettings, accentColor: AccentColor)
        -> IconConfig
    {
        if location != nil {
            return IconConfig(
                name: "mappin.and.ellipse",
                primaryColor: accentColor.color
            )
        }

        if trip != nil {
            return IconConfig(
                name: "suitcase"
            )
        }

        return settings.homeLocationIconConfig
    }

    // MARK: - Search Helper

    func searchQueryScore(_ query: PlannerSearchQuery?) -> Double? // nil means the event doesn't match the query
    {
        guard let query else {
            // Include. No query set.
            return 1.0
        }

        if !query.containsDatestamp(datestamp) {
            // Exclude. Doesn't match the time range.
            return nil
        }

        if query.text.isEmpty {
            // Include. No search text.
            return 1.0
        }

        if let location = location,
           let locationScore = query.score(for: location.name)
        {
            // Include. Location matches the search text.
            return locationScore
        }

        return nil
    }
}
