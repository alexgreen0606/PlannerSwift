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

// Clean

@MainActor
final class WeatherStore: ObservableObject {
    private let deviceLocationManager: DeviceLocationManager

    init(deviceLocationManager: DeviceLocationManager) {
        self.deviceLocationManager = deviceLocationManager
    }

    // Location Key -> Planner Start of Day -> Weather
    @Published var weatherCache: [String: [Date: DayWeather]] = [:]

    @Published var reloadTrigger: UUID? = nil
    @Published var loadedLocationKeys: Set<String> = []

    private let weatherService = WeatherService()

    func beginFreshReload() {
        loadedLocationKeys = []
        reloadTrigger = UUID()
    }

    func getWeather(for startOfDay: DateInRegion, at location: Location?)
        -> DayWeather?
    {
        guard let locationKey = getLocationKey(for: location) else {
            return nil
        }

        return weatherCache[locationKey]?[startOfDay.date]
    }

    func loadWeatherIfNeeded(
        location: Location?,
        region: Region
    ) async {
        guard let locationKey = getLocationKey(for: location) else {
            print(
                "ERROR WeatherStore.loadWeatherIfNeeded: Device location does not exist."
            )
            return
        }

        // Priority 1: Return cached data for this day/location.
        if loadedLocationKeys.contains(locationKey) {
            return
        } else {
            loadedLocationKeys.insert(locationKey)
        }

        let weatherLocation: CLLocation

        if let location {
            weatherLocation = CLLocation(
                latitude: location.latitude,
                longitude: location.longitude
            )
        } else if let deviceLocation = deviceLocationManager.deviceClLocation {
            weatherLocation = deviceLocation
        } else {
            print(
                "ERROR WeatherStore.loadWeatherIfNeeded: Device location does not exist."
            )
            return
        }

        do {
            let weather = try await weatherService.weather(for: weatherLocation)

            for dayWeather in weather.dailyForecast {

                let startOfDay = DateInRegion(
                    dayWeather.date,
                    region: region
                )
                .dateAt(.startOfDay)

                weatherCache[locationKey, default: [:]][
                    startOfDay.date
                ] = dayWeather
                
            }

        } catch {
            print("ERROR WeatherStore.loadWeatherIfNeeded: \(error)")
        }

    }

    // MARK: - Helper Function

    private func getLocationKey(for location: Location?) -> String? {
        location?.coordinateKey
            ?? deviceLocationManager.deviceClLocation?.coordinate.key
    }

}
