//
//  WeatherStore.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import Combine
import CoreLocation
import SwiftDate
import SwiftUI
import WeatherKit

@MainActor
final class WeatherStore: ObservableObject {
    static let shared = WeatherStore()
    private init() {}

    private let weatherService = WeatherService()
    private let locationManager = LocationManager.shared

    @Published private(set) var dayWeatherByDatestamp: [String: DayWeather] =
        [:]

    func loadWeather() async -> Set<String> {
        guard let deviceLocation = locationManager.location else {
            print("Device location not available.")
            return []
        }

        var loadedDatestamps = Set<String>()

        do {
            let weather = try await weatherService.weather(for: deviceLocation)

            for dayWeather in weather.dailyForecast {
                let currentDatestamp = dayWeather.date.datestamp
                dayWeatherByDatestamp[currentDatestamp] = dayWeather
                loadedDatestamps.insert(currentDatestamp)
            }

            return loadedDatestamps
        } catch {
            print("WeatherStore error:", error)
            return []
        }
    }

}
