//
//  PlannerWeather+.swift
//  Planner
//
//  Created by Alex Green on 7/20/26.
//

import Foundation
import WeatherKit

extension PlannerWeather {
    func syncWithDayWeather(_ dayWeather: DayWeather) {
        symbolName = dayWeather.symbolName
        condition = dayWeather.condition.description
        highTemp = dayWeather.highTemperature.converted(to: .fahrenheit).value
        lowTemp = dayWeather.lowTemperature.converted(to: .fahrenheit).value
        fetchedAt = Date.now
    }
}
