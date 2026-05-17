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

    private var highTemp: String {
        let temp = weatherData.highTemperature.converted(to: weatherUnit).value
        return "\(Int(ceil(temp)))°"
    }

    private var lowTemp: String {
        let temp = weatherData.lowTemperature.converted(to: weatherUnit).value
        return "\(Int(ceil(temp)))°"
    }

    var body: some View {
        HStack(spacing: 4) {
            value(highTemp, size: 11)
            Divider().frame(height: 12)
            value(lowTemp, size: 10)
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
