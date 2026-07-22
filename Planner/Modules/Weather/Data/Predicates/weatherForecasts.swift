//
//  plannerWeather.swift
//  Planner
//
//  Created by Alex Green on 7/17/26.
//

import CoreLocation
import SwiftUI

extension PlannerWeather {
    static func plannerWeather(
        for startOfDay: Date,
        coordinateId: String
    )
        -> Predicate<PlannerWeather>?
    {
        let locationDateId = getLocationDateId(
            coordinateId: coordinateId,
            startOfDay: startOfDay
        )

        return #Predicate<PlannerWeather> {
            $0.locationDateId == locationDateId
        }
    }
}
