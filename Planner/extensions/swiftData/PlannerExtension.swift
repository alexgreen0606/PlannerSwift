//
//  PlannerExtension.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import SwiftDate
import SwiftUI

extension Planner {

    var key: String {
        location?.coordinateKey ?? "\(datestamp)-DEFAULT_LOCATION"
    }

    // MARK: - Location Variables

    // Nil means the device location is used.
    func location(settings: PlannerSettings, deviceLocation: Location?)
        -> Location?
    {
        location ?? settings.validHomeLocation(deviceLocation: deviceLocation)
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
                primaryColor: accentColor.swiftUIColor
            )
        }

        return settings.homeLocationIconConfig
    }
}
