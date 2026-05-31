//
//  PlannerCardWeather.swift
//  Planner
//
//  Created by Alex Green on 5/12/26.
//

import SwiftDate
import SwiftUI
import WeatherKit

struct PlannerCardWeatherView: View {
    let planner: Planner
    let settings: PlannerSettings

    @EnvironmentObject private var weatherCacheService: WeatherCacheService
    @EnvironmentObject private var locationService: LocationService

    private var startOfDay: DateInRegion {
        planner.datestamp.startOfDay(in: planner.region(settings: settings))
    }

    private var plannerLocation: Location? {
        planner.location(
            settings: settings,
            deviceLocation: locationService.deviceLocation
        )
    }

    private var homeLocationLabel: String? {
        settings.homeLocationLabel(
            deviceLocation: locationService.deviceLocation
        )
    }

    private var showLocationLabel: Bool {
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
            deviceLocation: locationService.deviceLocation
        )
    }

    var body: some View {
        WeatherPreviewView(
            planner: planner,
            startAdorned: false,
            showLocationLabel: showLocationLabel,
            startOfDay: startOfDay,
            plannerLocation: plannerLocation,
            settings: settings
        )
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
