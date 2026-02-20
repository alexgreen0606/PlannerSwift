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

    func region(settings: PlannerSettings?) -> Region {
        location(settings: settings)?.region ?? .local
    }

    func location(settings: PlannerSettings?) -> Location? {
        if self.locationSource == .custom,
            let plannerLocation = self.location
        {
            return plannerLocation
        }

        if self.locationSource == .home,
            let homeLocation = settings?.homeLocation
        {
            return homeLocation
        }

        // Nil uses the device location.
        return nil
    }

    func locationLabel(settings: PlannerSettings?, localCityName: String?)
        -> String?
    {
        if self.locationSource == .custom,
            let plannerLocation = self.location
        {
            return plannerLocation.name
        }

        if self.locationSource == .home,
            let homeLocation = settings?.homeLocation
        {
            return homeLocation.name
        }

        return localCityName ?? "Current Location"
    }

    func locationIconConfig(
        settings: PlannerSettings?,
        accentColor: AccentColor
    ) -> IconConfig {
        if self.locationSource == .custom,
            self.location != nil
        {
            return IconConfig(
                name: "mappin.and.ellipse",
                primaryColor: accentColor.swiftUIColor,
                secondaryColor: Color.secondary
            )
        }

        if self.locationSource == .home,
            settings?.homeLocation != nil
        {
            return IconConfig(
                name: "house",
                primaryColor: Color.secondary,
                secondaryColor: nil
            )
        }

        return IconConfig(
            name: "location",
            primaryColor: Color.secondary,
            secondaryColor: nil
        )
    }

}
