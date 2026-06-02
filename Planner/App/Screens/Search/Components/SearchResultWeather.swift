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

    private var isSearching: Bool {
        activeQuery.isSearching
    }

    private var showLocationLabel: Bool {
        guard planner.searchQueryScore(activeQuery) != nil else {
            return false
        }

        if isSearching {
            return true
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
        if !isSearching || showLocationLabel {
            WeatherPreviewView(
                planner: planner,
                startAdorned: false,
                showLocationLabel: showLocationLabel,
                settings: settings
            )
        }
    }
}
