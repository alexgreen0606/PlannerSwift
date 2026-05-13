//
//  DayWeather.swift
//  Planner
//
//  Created by Alex Green on 1/2/26.
//

import Foundation
import WeatherKit

// Clean

extension DayWeather {

    func highTemp(in unit: UnitTemperature) -> String {
        let temp = self.highTemperature.converted(to: unit).value
        return "\(Int(ceil(temp)))°"
    }

    func lowTemp(in unit: UnitTemperature) -> String {
        let temp = self.lowTemperature.converted(to: unit).value
        return "\(Int(ceil(temp)))°"
    }

}
