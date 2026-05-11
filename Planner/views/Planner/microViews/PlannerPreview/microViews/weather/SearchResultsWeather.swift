//
//  SearchResultsWeather.swift
//  Planner
//
//  Created by Alex Green on 4/4/26.
//

import SwiftDate
import SwiftUI
import WeatherKit

// Clean

struct SearchResultsWeatherView: View {
    let plannerSearchQuery: PlannerSearchQuery
    let planner: Planner
    let plannerDay: DateInRegion
    let plannerLocation: Location?
    let settings: PlannerSettings

    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme
        .dark

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.colorScheme) private var systemColorScheme
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    var isDarkMode: Bool {
        switch appColorScheme {
        case .dark: return true
        case .light: return false
        case .system: return systemColorScheme == .dark
        }
    }

    private var isSearching: Bool {
        plannerSearchQuery.isSearching
    }

    private var homeLocationLabel: String? {
        settings.homeLocationLabel(
            deviceLocation: deviceLocationManager.deviceLocation
        )
    }

    private var weatherData: DayWeather? {
        guard !isSearching else {
            // Hide the weather when searching.
            return nil
        }

        return weatherStore.getWeather(
            for: plannerDay,
            at: plannerLocation
        )
    }

    private var showLocationLabel: Bool {
        guard planner.searchQueryScore(plannerSearchQuery) != nil else {
            return false
        }

        if locationLabel != homeLocationLabel {
            // Show the location when the planner's location
            // differs from the home location.
            return true
        }

        return false
    }

    private var showLocationIcon: Bool {
        guard let locationLabel else {
            return false
        }

        if weatherData != nil {
            // Never show location icon when weather exists.
            return false
        }

        if locationLabel != homeLocationLabel, weatherData == nil {
            // Show the location icon when the planner's location
            // differs from the home location and the weather is loading.
            return true
        }

        return false
    }

    private var locationLabel: String? {
        planner.locationLabel(
            settings: settings,
            deviceLocation: deviceLocationManager.deviceLocation
        )
    }

    private var locationIconConfig: IconConfig {
        planner.locationIconConfig(
            settings: settings,
            accentColor: accentColor
        )
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {

            if let weatherData {
                HStack {

                    VStack(alignment: .trailing, spacing: 0) {
                        Text(weatherData.condition.description)
                            .font(.system(size: 12, design: .rounded))

                        TemperatureView(weatherData: weatherData)
                    }

                    Image(systemName: weatherData.symbolName)
                        .symbolVariant(isDarkMode ? .fill : .none)
                        .symbolRenderingMode(
                            isDarkMode ? .multicolor : .monochrome
                        )
                        .imageScale(.medium)
                        .frame(maxHeight: .infinity)
                }
            }

            if showLocationLabel, let locationLabel  {
                HStack(spacing: 6) {
                    if showLocationIcon {
                        Image(systemName: locationIconConfig.name)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 11, height: 11)
                            .foregroundStyle(
                                locationIconConfig.primaryColor,
                                locationIconConfig.secondaryColor
                            )
                    }

                    if showLocationLabel {
                        Text(locationLabel)
                            .foregroundStyle(
                                Color.secondary
                            )
                            .font(.system(size: 10))
                    }
                }
            }

        }
        .animateAsynchronousAction(from: weatherData != nil)
        .animateAsynchronousAction(from: locationLabel != nil)
        //        VStack(alignment: .trailing) {
        //            HStack(alignment: .bottom) {
        //
        //                VStack(alignment: .trailing, spacing: 0) {
        //
        //                    if let weatherData {
        //                        Text(weatherData.condition.description)
        //                            .font(.system(size: 12, design: .rounded))
        //                    }
        //
        //                    if let locationLabel {
        //                        HStack(spacing: 6) {
        //                            if showLocationIcon {
        //                                Image(systemName: locationIconConfig.name)
        //                                    .resizable()
        //                                    .scaledToFit()
        //                                    .frame(width: 11, height: 11)
        //                                    .foregroundStyle(
        //                                        locationIconConfig.primaryColor,
        //                                        locationIconConfig.secondaryColor
        //                                    )
        //                            }
        //
        //                            if showLocationLabel {
        //                                Text(locationLabel)
        //                                    .foregroundStyle(
        //                                        Color.secondary
        //                                    )
        //                                    .font(.system(size: 10))
        //                            }
        //                        }
        //                    }
        //                }
        //
        //                if let weatherData {
        //                    Image(systemName: weatherData.symbolName)
        //                        .symbolVariant(isDarkMode ? .fill : .none)
        //                        .symbolRenderingMode(
        //                            isDarkMode ? .multicolor : .monochrome
        //                        )
        //                        .imageScale(.medium)
        //                        .frame(maxHeight: .infinity)
        //                }
        //            }
        //
        //            if let weatherData {
        //                TemperatureView(weatherData: weatherData)
        //            }
        //
        //        }
        //        .animateAsynchronousAction(from: weatherData != nil)
        //        .animateAsynchronousAction(from: locationLabel != nil)
    }

}
