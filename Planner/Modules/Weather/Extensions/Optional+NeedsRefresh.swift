//
//  Optional+NeedsRefresh.swift
//  Planner
//
//  Created by Alex Green on 7/21/26.
//

import Foundation
import SwiftDate

extension Optional where Wrapped: PlannerWeather {
    func needsRefresh(
        lastRefresh: Double
    ) -> Bool {
        guard let self else { return true }

        return self.fetchedAt.addingTimeInterval(
            WeatherData.STALE_TIME_OFFSET
        ).isInPast || self.fetchedAt.timeIntervalSince1970 < lastRefresh
    }
}
