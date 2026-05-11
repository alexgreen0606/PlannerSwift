//
//  Weather.swift
//  Planner
//
//  Created by Alex Green on 5/9/26.
//

import SwiftDate
import SwiftUI
import WeatherKit

struct WeatherView: View {
    let planner: Planner
    let plannerDay: DateInRegion
    let plannerLocation: Location
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

    private var weatherData: DayWeather? {
        weatherStore.getWeather(
            for: plannerDay,
            at: plannerLocation
        )
    }

    var body: some View {
        VStack(alignment: .trailing) {
            HStack(alignment: .bottom) {

                VStack(alignment: .trailing, spacing: 0) {

                    if let weatherData {
                        Text(weatherData.condition.description)
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(Color.label)
                    }

                    if let weatherData {
                        TemperatureView(weatherData: weatherData).scaleEffect(0.9)
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

        }
        .animateAsynchronousAction(from: weatherData != nil)
    }

}
