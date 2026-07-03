//
//  PlannerEventLocationHelpers.swift
//  Planner
//
//  Created by Alex Green on 6/14/26.
//

import SwiftDate

protocol PlannerEventLocationHelpers {
    var location: Location? { get }
}

extension PlannerEventLocationHelpers {
    func region(
        planner: Planner?,
        settings: Settings,
        deviceLocation: Location?
    ) -> Region {
        location(
            planner: planner,
            settings: settings,
            deviceLocation: deviceLocation
        )?.region ?? .local
    }

    func locationLabel(
        planner: Planner?,
        settings: Settings,
        deviceLocation: Location?
    ) -> String {
        location(
            planner: planner,
            settings: settings,
            deviceLocation: deviceLocation
        )?.name ?? "Current Location"
    }

    // MARK: - Helper Function

    private func location(
        planner: Planner?,
        settings: Settings,
        deviceLocation: Location?
    ) -> Location? {
        location
            ?? planner?.location(
                settings: settings,
                deviceLocation: deviceLocation
            )
    }
}
