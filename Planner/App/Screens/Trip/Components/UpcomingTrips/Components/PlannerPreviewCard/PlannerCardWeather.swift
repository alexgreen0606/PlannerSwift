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
    let customDefaultLocationLabel: String?
    let settings: Settings

    private var homeLocationLabel: String? {
        settings.homeLocationLabel
    }

    private var locationLabel: String? {
        planner.locationLabel(
            settings: settings
        )
    }

    private var showLocationLabel: Bool {
        let defaultLocationLabel =
            customDefaultLocationLabel ?? homeLocationLabel

        if locationLabel != defaultLocationLabel {
            // Show the location when the planner's location
            // differs from the home location.
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
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
