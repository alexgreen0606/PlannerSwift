//
//  WeatherChip.swift
//  Planner
//
//  Created by Alex Green on 4/1/26.
//

import SwiftUI
import WeatherKit

struct WeatherChipView: View {
    let planner: Planner
    let settings: Settings

    private let ICON_SIZE: CGFloat = 17

    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme
        .dark

    @Environment(\.colorScheme) private var systemColorScheme
    @EnvironmentObject private var locationService: LocationService

    private var isDarkMode: Bool {
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
            if let plannerWeather {
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: plannerWeather.symbolName)
                            .resizable()
                            .scaledToFit()
                            .symbolVariant(isDarkMode ? .fill : .none)
                            .symbolRenderingMode(
                                isDarkMode ? .multicolor : .monochrome
                            )
                            .frame(width: ICON_SIZE, height: ICON_SIZE)

                        Value(plannerWeather.condition)
                    }

                    TemperatureView(plannerWeather: plannerWeather)
                }
                .glassChip(
                    height: PlannerLayout.CHIP_HEIGHT,
                    onTap: openWeatherApp
                )
            }
        }
    }

    // MARK: - Functions

    private func openWeatherApp() {
        guard let url = URL(string: "weather://") else { return }
        UIApplication.shared.open(url)
    }
}
