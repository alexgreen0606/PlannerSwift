//
//  Temperature.swift
//  Planner
//
//  Created by Alex Green on 4/4/26.
//

import SwiftUI
import WeatherKit

struct TemperatureView: View {
    let plannerWeather: PlannerWeather

    private let weatherUnit: UnitTemperature =
        Locale.current.measurementSystem == .metric ? .celsius : .fahrenheit

    private var highTemp: String {
        let measurement = Measurement(
            value: plannerWeather.highTemp,
            unit: UnitTemperature.fahrenheit
        )

        let converted = measurement.converted(to: weatherUnit)

        return "\(Int(converted.value.rounded()))°"
    }

    private var lowTemp: String {
        let measurement = Measurement(
            value: plannerWeather.lowTemp,
            unit: UnitTemperature.fahrenheit
        )

        let converted = measurement.converted(to: weatherUnit)

        return "\(Int(converted.value.rounded()))°"
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 4) {
            value(highTemp, size: 11)
            Divider().frame(height: 12)
            value(lowTemp, size: 10)
        }
    }

    // MARK: - View Builder

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
