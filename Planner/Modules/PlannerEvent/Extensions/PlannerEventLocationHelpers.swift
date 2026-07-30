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
        settings: Settings
    ) -> Region {
        location(
            planner: planner,
            settings: settings
        )?.region ?? .local
    }

    func locationLabel(
        planner: Planner?,
        settings: Settings
    ) -> String {
        location(
            planner: planner,
            settings: settings
        )?.name ?? "Current Location"
    }
    
    func coordinateId(
        planner: Planner?,
        settings: Settings
    ) -> String {
        location(
            planner: planner,
            settings: settings
        ).coordinateId
    }

    // MARK: - Helper Function

    private func location(
        planner: Planner?,
        settings: Settings
    ) -> Location? {
        location
            ?? planner?.location(
                settings: settings
            )
    }
}
