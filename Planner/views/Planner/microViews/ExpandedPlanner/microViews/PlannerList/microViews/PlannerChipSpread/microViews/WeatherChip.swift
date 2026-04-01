//
//  WeatherChip.swift
//  Planner
//
//  Created by Alex Green on 4/1/26.
//

import SwiftUI
import WeatherKit

// Clean

struct WeatherChipView: View {
    let weatherData: DayWeather

    private let weatherUnit: UnitTemperature =
        Locale.current.measurementSystem == .metric ? .celsius : .fahrenheit

    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme
        .system

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

                Text(weatherData.condition.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.label)
            }

            HStack(alignment: .center, spacing: 4) {
                Text(weatherData.highTemp(in: weatherUnit))
                    .font(
                        .system(
                            size: 11,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(Color.label)

                Divider().frame(height: 16)

                Text(weatherData.lowTemp(in: weatherUnit))
                    .font(
                        .system(
                            size: 10,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(Color.label)
            }
        }
        .glassChip(color: nil, onTap: openWeatherApp)
        .contentShape(Rectangle())
        .onTapGesture(perform: openWeatherApp)
    }

    // MARK: - Functions

    private func openWeatherApp() {
        guard let url = URL(string: "weather://") else { return }
        UIApplication.shared.open(url)
    }

}
