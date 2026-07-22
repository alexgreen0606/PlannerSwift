//
//  PlannerWeather.swift
//  Planner
//
//  Created by Alex Green on 7/17/26.
//

import SwiftData
import SwiftDate
import SwiftUI
import WeatherKit

@Model
class PlannerWeather {

    var coordinateId: String = ""
    var startOfDay: Date = Date.now

    /// Combines coordinateId and startOfDay to make a unique identifier.
    var locationDateId: String = ""

    var symbolName: String = ""
    var condition: String = ""

    /// Stored in Farenheit.
    var highTemp: Double = 0.0
    var lowTemp: Double = 0.0

    var fetchedAt: Date = Date.now

    init(coordinateId: String, startOfDay: Date, dayWeather: DayWeather) {

        self.coordinateId = coordinateId
        self.startOfDay = startOfDay

        self.locationDateId = getLocationDateId(
            coordinateId: coordinateId,
            startOfDay: startOfDay
        )

        self.symbolName = dayWeather.symbolName
        self.condition = dayWeather.condition.description
        self.highTemp =
            dayWeather.highTemperature.converted(to: .fahrenheit).value
        self.lowTemp =
            dayWeather.lowTemperature.converted(to: .fahrenheit).value
    }
}
