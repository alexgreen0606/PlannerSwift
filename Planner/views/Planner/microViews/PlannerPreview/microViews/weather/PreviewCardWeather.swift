//
//  PreviewCardWeather.swift
//  Planner
//
//  Created by Alex Green on 3/11/26.
//

import SwiftDate
import SwiftUI
import WeatherKit

// Clean

struct PreviewCardWeatherView: View {
    let planner: Planner
    let plannerDay: DateInRegion
    let plannerLocation: Location?
    let settings: PlannerSettings

    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme
        .system

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.colorScheme) private var systemColorScheme
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    private var weatherData: DayWeather? {
        weatherStore.getWeather(
            for: plannerDay,
            at: plannerLocation
        )
    }

    private var locationLabel: String {
        planner.locationLabel(
            settings: settings,
            deviceLocation: deviceLocationManager.deviceLocation
        )
    }

    private var locationIconConfig: IconConfig? {
        guard weatherData == nil else {
            return nil
        }
        return planner.locationIconConfig(
            settings: settings,
            accentColor: accentColor
        )
    }

    var isDarkMode: Bool {
        switch appColorScheme {
        case .dark: return true
        case .light: return false
        case .system: return systemColorScheme == .dark
        }
    }

    var body: some View {
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

                    AdornedValueView(
                        locationLabel,
                        color: Color.secondary,
                        iconConfig: locationIconConfig,
                        scale: 0.7
                    )

                    Spacer()

                    if let weatherData {
                        TemperatureView(weatherData: weatherData)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .frame(height: 30)
        .animateAsynchronousAction(from: weatherData)
    }

}
