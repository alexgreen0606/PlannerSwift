//
//  WeatherChip.swift
//  Planner
//
//  Created by Alex Green on 4/1/26.
//

import SwiftUI
import WeatherKit

struct WeatherChipView: View {
    let weatherData: DayWeather

    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme
        .dark

    @Environment(\.colorScheme) private var systemColorScheme

    private var isDarkMode: Bool {
        switch appColorScheme {
        case .dark: return true
        case .light: return false
        case .system: return systemColorScheme == .dark
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(alignment: .center, spacing: 4) {
                Image(systemName: weatherData.symbolName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .symbolVariant(isDarkMode ? .fill : .none)
                    .symbolRenderingMode(
                        isDarkMode ? .multicolor : .monochrome
                    )

                ValueView(weatherData.condition.description)
            }

            TemperatureView(weatherData: weatherData)
        }
        .glassChip(height: PlannerLayout.CHIP_HEIGHT, onTap: openWeatherApp)
    }

    // MARK: - Functions

    private func openWeatherApp() {
        guard let url = URL(string: "weather://") else { return }
        UIApplication.shared.open(url)
    }
}
