//
//  DayWeather.swift
//  Planner
//
//  Created by Alex Green on 1/2/26.
//

import WeatherKit
import Foundation

extension DayWeather {
    func highTempString(in unit: UnitTemperature) -> String {
        let temp = self.highTemperature.converted(to: unit)
        return "\(Int(temp.value))°"
    }

    func lowTempString(in unit: UnitTemperature) -> String  {
        let temp = self.lowTemperature.converted(to: unit)
        return "\(Int(temp.value))°"
    }
}
