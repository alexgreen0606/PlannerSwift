//
//  WeatherInfo.swift
//  Planner
//
//  Created by Alex Green on 3/11/26.
//

import SwiftDate
import SwiftUI
import WeatherKit

// Clean

struct WeatherInfoView: View {
    let previewType: PlannerPreviewType
    let plannerSearchQuery: PlannerSearchQuery?
    let planner: Planner
    let plannerDay: DateInRegion
    let plannerLocation: Location?
    let settings: PlannerSettings

    private let weatherUnit: UnitTemperature =
        Locale.current.measurementSystem == .metric ? .celsius : .fahrenheit

    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme
        .system

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
        plannerSearchQuery?.isSearching ?? false
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
        guard let locationLabel else {
            return false
        }

        switch previewType {
        case .planner:
            // TODO: implement
            return false
        case .search:
            if weatherData != nil {
                // Show location whenever weather exists.
                return true
            }

            if locationLabel != settings.homeLocationLabel {
                // Show the location when the planner's location
                // differs from the home location.
                return true
            }

            return false
        case .trip:
            // TODO: implement
            return false
        }
    }

    private var showLocationIcon: Bool {
        guard let locationLabel else {
            return false
        }

        switch previewType {
        case .planner:
            // TODO: implement
            return false
        case .search:
            if weatherData != nil {
                // Never show location icon when weather exists.
                return false
            }

            if locationLabel != settings.homeLocationLabel, weatherData == nil {
                // Show the location icon when the planner's location
                // differs from the home location and the weather is loading.
                return true
            }

            return false
        case .trip:
            // TODO: implement
            return false
        }
    }

    private var locationLabel: String? {
        if planner.searchQueryScore(plannerSearchQuery) != nil {
            return planner.locationLabel(
                settings: settings,
                deviceLocation: deviceLocationManager.deviceLocation
            )
        }
        return nil
    }

    private var locationIconConfig: IconConfig {
        planner.locationIconConfig(
            settings: settings,
            accentColor: accentColor
        )
    }

    var body: some View {
        if previewType != .search {
            fullWidthView
        } else {
            condensedWidthView
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private var fullWidthView: some View {
        HStack(alignment: .bottom) {
            if let weatherData {
                Image(systemName: weatherData.symbolName)
                    .symbolVariant(isDarkMode ? .fill : .none)
                    .symbolRenderingMode(
                        isDarkMode ? .multicolor : .monochrome
                    )
                    .imageScale(.medium)
                    .frame(maxHeight: .infinity)
            }

            VStack(alignment: .leading, spacing: 0) {

                if let weatherData {
                    Text(weatherData.condition.description)
                        .font(.system(size: 12, design: .rounded))
                }

                HStack {

                    if let locationLabel {
                        HStack(spacing: 6) {
                            if weatherData == nil {
                                Image(systemName: locationIconConfig.name)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 11, height: 11)
                                    .foregroundStyle(
                                        locationIconConfig.primaryColor,
                                        locationIconConfig.secondaryColor
                                    )
                            }

                            Text(locationLabel)
                                .foregroundStyle(
                                    Color.secondary
                                )
                                .font(.system(size: 10))
                        }
                    }

                    Spacer()

                    if let weatherData {
                        HStack(alignment: .center, spacing: 4) {
                            Text(
                                weatherData.highTemp(in: weatherUnit)
                            )
                            .font(
                                .system(
                                    size: 11,
                                    weight: .bold,
                                    design: .rounded
                                )
                            )
                            Divider().frame(height: 16)
                            Text(weatherData.lowTemp(in: weatherUnit))
                                .font(
                                    .system(
                                        size: 10,
                                        weight: .bold,
                                        design: .rounded
                                    )
                                )
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .frame(height: 30)
        .animateAsynchronousAction(from: weatherData != nil)
        .animateAsynchronousAction(from: locationLabel != nil)
    }

    @ViewBuilder
    private var condensedWidthView: some View {
        VStack(alignment: .trailing) {
            HStack(alignment: .bottom) {

                VStack(alignment: .trailing, spacing: 0) {

                    if let weatherData {
                        Text(weatherData.condition.description)
                            .font(.system(size: 12, design: .rounded))
                    }

                    if let locationLabel {
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

                if let weatherData {
                    Image(systemName: weatherData.symbolName)
                        .symbolVariant(isDarkMode ? .fill : .none)
                        .symbolRenderingMode(
                            isDarkMode ? .multicolor : .monochrome
                        )
                        .imageScale(.medium)
                        .frame(maxHeight: .infinity)
                }
            }

            if let weatherData {
                HStack(alignment: .center, spacing: 4) {
                    Text(weatherData.highTemp(in: weatherUnit))
                        .font(
                            .system(
                                size: 11,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                    Divider().frame(height: 16)
                    Text(weatherData.lowTemp(in: weatherUnit))
                        .font(
                            .system(
                                size: 10,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                }
            }

        }
        .animateAsynchronousAction(from: weatherData != nil)
        .animateAsynchronousAction(from: locationLabel != nil)
    }

}
