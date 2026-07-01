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
    var safeRoutineEventRecordContexts: [RoutineEventRecordContext] {
        routineEventRecordContexts ?? []
    }

    var safeExcludeRoutine: Bool {
        if let customExclusion = excludeRoutine {
            return customExclusion
        }
        return trip?.excludeRoutines ?? false
    }

    func startOfDay(settings: PlannerSettings) -> DateInRegion {
        datestamp.startOfDay(in: region(settings: settings))
    }

    // MARK: - Location Variables

    var locationKey: String {
        let timeZoneKey = location?.timeZoneIdentifier ?? "HOME_LOCATION"
        return "\(datestamp)-\(timeZoneKey)"
    }

    func location(settings: PlannerSettings, deviceLocation: Location?)
        // Note: nil means the device location is used and hasn't loaded yet.
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
