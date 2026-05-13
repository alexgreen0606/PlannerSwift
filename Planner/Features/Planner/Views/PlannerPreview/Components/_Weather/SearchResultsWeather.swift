//
//  SearchResultsWeather.swift
//  Planner
//
//  Created by Alex Green on 4/4/26.
//

import SwiftDate
import SwiftUI
import WeatherKit

struct SearchResultsWeatherView: View {
    let plannerSearchQuery: PlannerSearchQuery
    let planner: Planner
    let plannerDay: DateInRegion
    let plannerLocation: Location?
    let settings: PlannerSettings

    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var LocationService: LocationService

    private var homeLocationLabel: String? {
        settings.homeLocationLabel(
            deviceLocation: LocationService.deviceLocation
        )
    }

    private var showLocationLabel: Bool {
        guard planner.searchQueryScore(plannerSearchQuery) != nil else {
            return false
        }
        
        // TODO: still show if it matches the home location AND matches the query

        if locationLabel != homeLocationLabel {
            // Show the location when the planner's location
            // differs from the home location.
            return true
        }

        return false
    }

    private var locationLabel: String? {
        planner.locationLabel(
            settings: settings,
            deviceLocation: LocationService.deviceLocation
        )
    }

    var body: some View {
        WeatherPreviewView(
            planner: planner,
            startAdorned: false,
            showLocationLabel: showLocationLabel,
            plannerDay: plannerDay,
            plannerLocation: plannerLocation,
            settings: settings
        )
    }

}
