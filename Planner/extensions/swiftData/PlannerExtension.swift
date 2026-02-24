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
        location?.coordinateKey ?? "\(datestamp)-CURRENT_LOCATION"
    }

    // Nil means the device location is used.
    func location(settings: PlannerSettings) -> Location? {
        switch locationSource {
        case .custom:
            guard let location else {
                fatalError(
                    "ERROR PlannerExtention.location: Planner location is set to custom but no location is set."
                )
            }

            return location
        case .home:
            return settings.homeLocation
        case .current:
            return nil
        case .planner:
            fatalError(
                "ERROR PlannerExtension.location: Planner location source is set to planner (not allowed)."
            )
        }
    }

    func locationIconConfig(settings: PlannerSettings, accentColor: AccentColor)
        -> IconConfig
    {
        switch locationSource {
        case .custom:
            return IconConfig(
                name: "mappin.and.ellipse",
                primaryColor: accentColor.swiftUIColor,
                secondaryColor: Color.secondary
            )
        case .home:
            return settings.homeLocationIconConfig
        case .current:
            return IconConfig(
                name: "location",
                primaryColor: Color.secondary,
                secondaryColor: nil
            )
        case .planner:
            fatalError(
                "ERROR PlannerExtension.locationIconConfig: Planner location source is set to planner (not allowed)."
            )
        }
    }

    func region(settings: PlannerSettings) -> Region {
        location(settings: settings)?.region ?? .local
    }

    func locationLabel(localCityName: String, settings: PlannerSettings)
        -> String
    {
        location(settings: settings)?.name ?? localCityName
    }

}
