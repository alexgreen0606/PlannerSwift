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
    let planner: Planner
    let plannerStartOfDay: DateInRegion
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

    private var weatherData: DayWeather? {
        weatherStore.getWeather(for: plannerStartOfDay, at: plannerLocation)
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
        if previewType == .planner {
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
                            if weatherData == nil, planner.location != nil {
                                Image(systemName: locationIconConfig.name)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 11, height: 11)
                                    .foregroundStyle(
                                        locationIconConfig.primaryColor,
                                        locationIconConfig.secondaryColor
                                    )
                            }

                            if weatherData != nil || planner.location != nil {
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
