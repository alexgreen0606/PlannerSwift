//
//  PlannerListWeather.swift
//  Planner
//
//  Created by Alex Green on 4/4/26.
//

import SwiftDate
import SwiftUI
import WeatherKit

struct PlannerListWeatherView: View {
    let planner: Planner
    let settings: Settings

    @EnvironmentObject private var plannerService: PlannerService

    private var showLocationLabel: Bool {
        if let activeQuery = plannerService.activeQuery,
            !activeQuery.isDefault
        {
            return planner.searchQueryScore(activeQuery) != nil
        }

        let homeLocationLabel = settings.homeLocationLabel

        let locationLabel = planner.locationLabel(
            settings: settings
        )

        if locationLabel != homeLocationLabel {
            return true
        }

        return false
    }

    // MARK: - Body

    var body: some View {
        WeatherPreviewView(
            planner: planner,
            startAdorned: false,
            showLocationLabel: showLocationLabel,
            settings: settings
        )
    }
}
