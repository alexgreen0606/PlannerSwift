//
//  Planner+.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import Fuse
import SwiftDate
import SwiftUI

extension Planner {

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

    // TODO: maybe this should relate to timezone yeah?
    var plannerLocationId: String {
        let locationKey = location?.coordinateId ?? "HOME_LOCATION"
        return "\(datestamp)-\(locationKey)"
    }

    func location(settings: PlannerSettings, deviceLocation: Location?)
        /// Note: nil means the device location is used and hasn't loaded yet.
        -> Location?
    {
        location ?? trip?.location
            ?? settings.homeLocation(deviceLocation: deviceLocation)
    }

    func region(settings: PlannerSettings) -> Region {
        location?.region ?? trip?.location?.region ?? settings.homeRegion
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

}
