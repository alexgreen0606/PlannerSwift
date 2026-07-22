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
    @EnvironmentObject private var locationService: LocationService

    private var locationLabel: String {
        planner.locationLabel(
            settings: settings,
            deviceLocation: locationService.deviceLocation
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
        PlannerWeatherLoaderView(
            planner: planner,
            settings: settings
        ) { plannerWeather in
            HStack {
                if startAdorned, let plannerWeather {
                    weatherIcon(systemImageName: plannerWeather.symbolName)
                }
                
                VStack(
                    alignment: startAdorned ? .leading : .trailing,
                    spacing: 0
                ) {
                    if let plannerWeather {
                        TemperatureView(plannerWeather: plannerWeather)
                    }
                    
                    if showLocationLabel {
                        AdornedValue(
                            locationLabel,
                            iconConfig: locationIconConfig(
                                hasWeather: plannerWeather != nil
                            ),
                            color: Color.secondary,
                            scale: 0.7
                        )
                    }
                }
                
                if !startAdorned, let plannerWeather {
                    weatherIcon(systemImageName: plannerWeather.symbolName)
                }
            }
            .frame(height: 30)
        }
    }
    
    // MARK: - Conditional Var
    
    /// Only display the location icon when weather doesn't exist.
    private func locationIconConfig(hasWeather: Bool) -> IconConfig? {
        guard !hasWeather else {
            return nil
        }

        return planner.locationIconConfig(
            settings: settings,
            accentColor: accentColor
        )
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
