//
//  SearchResultWeather.swift
//  Planner
//
//  Created by Alex Green on 4/4/26.
//

import SwiftDate
import SwiftUI
import WeatherKit

struct SearchResultWeatherView: View {
    let activeQuery: PlannerSearchQuery
    let planner: Planner
    let settings: PlannerSettings

    @EnvironmentObject private var weatherCacheService: WeatherCacheService
    @EnvironmentObject private var locationService: LocationService

    private var isFiltering: Bool {
        activeQuery.isFiltering
    }

    private var showLocationLabel: Bool {
        if isFiltering {
            return planner.searchQueryScore(activeQuery) != nil
        }

        let homeLocationLabel = settings.homeLocationLabel(
            deviceLocation: locationService.deviceLocation
        )

        let locationLabel = planner.locationLabel(
            settings: settings,
            deviceLocation: locationService.deviceLocation
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
