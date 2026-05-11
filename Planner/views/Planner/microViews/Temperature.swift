//
//  Temperature.swift
//  Planner
//
//  Created by Alex Green on 4/4/26.
//

import SwiftUI
import WeatherKit

struct TemperatureView: View {
    let weatherData: DayWeather

    private let weatherUnit: UnitTemperature =
        Locale.current.measurementSystem == .metric ? .celsius : .fahrenheit

    var body: some View {
        HStack(spacing: 4) {
            value(
                weatherData.highTemp(in: weatherUnit),
                size: 11
            )
            Divider().frame(height: 16)
            value(weatherData.lowTemp(in: weatherUnit), size: 10)
        }
    }

    private func value(_ text: String, size: CGFloat) -> some View {
        Text(text)
            .font(
                .system(
                    size: size,
                    weight: .bold,
                    design: .rounded
                )
            )
            .foregroundStyle(Color.label)
    }

}
