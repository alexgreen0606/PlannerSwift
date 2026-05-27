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
    let plannerDay: DateInRegion
    let plannerLocation: Location?
    let settings: PlannerSettings

    @EnvironmentObject private var weatherStore: WeatherCacheService
    @EnvironmentObject private var locationService: LocationService

    private var showLocationLabel: Bool {
        guard planner.searchQueryScore(activeQuery) != nil else {
            return false
        }

        if activeQuery.isSearching {
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
