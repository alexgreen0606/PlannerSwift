//
//  DayWeather.swift
//  Planner
//
//  Created by Alex Green on 1/2/26.
//

import WeatherKit
import Foundation

extension DayWeather {
    var highTempString: String {
        let temp = self.highTemperature
        return "\(Int(temp.value))°"
    }

    var lowTempString: String {
        let temp = self.lowTemperature
        return "\(Int(temp.value))°"
    }
}
