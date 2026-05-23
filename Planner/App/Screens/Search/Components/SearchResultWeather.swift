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

    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var locationService: LocationService

    private var showLocationLabel: Bool {
        guard planner.searchQueryScore(activeQuery) != nil else {
            return false
        }

        let homeLocationLabel = settings.homeLocationLabel(
            deviceLocation: locationService.deviceLocation
        )

        let locationLabel = planner.locationLabel(
            settings: settings,
            deviceLocation: locationService.deviceLocation
        )

        // TODO: still show if it matches the home location AND matches the query

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
