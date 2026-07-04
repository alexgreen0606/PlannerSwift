//
//  WeatherPreview.swift
//  Planner
//
//  Created by Alex Green on 5/12/26.
//

import SwiftUI
import WeatherKit

struct WeatherPreviewView: View {
    private let planner: Planner
    private let startAdorned: Bool
    private let showLocationLabel: Bool
    private let settings: Settings

    init(
        planner: Planner,
        startAdorned: Bool = true,
        showLocationLabel: Bool,
        settings: Settings
    ) {
        self.planner = planner
        self.startAdorned = startAdorned
        self.showLocationLabel = showLocationLabel
        self.settings = settings
    }

    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme
        .dark

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.colorScheme) private var systemColorScheme
    @EnvironmentObject private var weatherCacheService: WeatherCacheService
    @EnvironmentObject private var locationService: LocationService

    private var weatherData: DayWeather? {
        let startOfDay = planner.startOfDay(settings: settings)
        let plannerLocation = planner.location(
            settings: settings,
            deviceLocation: locationService.deviceLocation
        )

        return weatherCacheService.weather(
            for: startOfDay,
            at: plannerLocation
        )
    }

    private var locationLabel: String {
        planner.locationLabel(
            settings: settings,
            deviceLocation: locationService.deviceLocation
        )
    }

    /// Only display the location icon when weather data doesn't exist.
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

    // MARK: - Body

    var body: some View {
        HStack {
            if startAdorned, let weatherData {
                weatherIcon(systemImageName: weatherData.symbolName)
            }

            VStack(alignment: startAdorned ? .leading : .trailing, spacing: 0) {
                if let weatherData {
                    TemperatureView(weatherData: weatherData)
                }

                if showLocationLabel {
                    AdornedValue(
                        locationLabel,
                        iconConfig: locationIconConfig,
                        color: Color.secondary,
                        scale: 0.7
                    )
                }
            }

            if !startAdorned, let weatherData {
                weatherIcon(systemImageName: weatherData.symbolName)
            }
        }
        .animateLazyAction(from: weatherData)
        .frame(height: 30)
    }

    // MARK: - View Builders

    private func weatherIcon(systemImageName: String) -> some View {
        Image(systemName: systemImageName)
            .symbolVariant(isDarkMode ? .fill : .none)
            .symbolRenderingMode(
                isDarkMode ? .multicolor : .monochrome
            )
            .imageScale(.medium)
            .frame(maxHeight: .infinity)
    }
}
