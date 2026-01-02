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

    func loadWeather(for datestamp: String) async {
        guard let targetDay = datestamp.date?.in(region: .local) else { return }
        guard let deviceLocation = locationManager.location else {
            print("Device location not available.")
            return
        }

        do {
            let weather = try await weatherService.weather(
                for: deviceLocation
            )

            guard
                let dayWeather = weather.dailyForecast.first(
                    where: {
                        $0.date
                            .in(region: .local)
                            .dateAtStartOf(.day)
                            == targetDay
                    }
                )
            else {
                return
            }

            dayWeatherByDatestamp[datestamp] = dayWeather
        } catch {
            print("WeatherStore error:", error)
        }
    }

    // Refreshes all currently loaded weather data.
    func refreshAllWeather() async {
        let datestamps = dayWeatherByDatestamp.keys
        for datestamp in datestamps {
            await loadWeather(for: datestamp)
        }
    }
}
