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
    private let locationManager: DeviceLocationManager

    init(locationManager: DeviceLocationManager) {
        self.locationManager = locationManager
    }

    private let weatherService = WeatherService()

    // Location Key -> Date (Region Start Of Day) -> Weather
    @Published var weatherMap: [String: [Date: DayWeather]] =
        [:]

    @Published var loadId: UUID = UUID()
    @Published var loadedLocationKeys: Set<String> = []

    func resetWeather() {
        loadedLocationKeys = []
        loadId = UUID()
    }

    func getWeather(for startOfDay: DateInRegion, at location: Location?)
        -> DayWeather?
    {
        guard let locationKey = getLocationKey(for: location) else {
            return nil
        }

        return weatherMap[locationKey]?[startOfDay.date]
    }

    func loadWeatherIfNeeded(
        location: Location?,
        region: Region
    ) async {
        let weatherLocation: CLLocation

        guard let locationKey = getLocationKey(for: location) else {
            print(
                "ERROR WeatherStore.loadWeatherIfNeeded: Failed to build a locationKey."
            )
            return
        }

        if loadedLocationKeys.contains(locationKey) {
            return
        } else {
            print(
                "\(location?.name ?? locationManager.cityName ?? "Current Location"): Cache miss. Fetching."
            )
            loadedLocationKeys.insert(locationKey)
        }

        if let location {
            weatherLocation = CLLocation(
                latitude: location.latitude,
                longitude: location.longitude
            )
        } else if let deviceLocation = locationManager.deviceClLocation {
            weatherLocation = deviceLocation
        } else {
            print(
                "ERROR WeatherStore.loadWeatherIfNeeded: Failed to build a weatherLocation."
            )
            return
        }

        do {
            let weather = try await weatherService.weather(for: weatherLocation)

            for dayWeather in weather.dailyForecast {

                let dayInPlannerRegion = DateInRegion(
                    dayWeather.date,
                    region: region
                )
                .dateAt(.startOfDay)

                weatherMap[locationKey, default: [:]][dayInPlannerRegion.date] =
                    dayWeather
            }

        } catch {
            print("ERROR WeatherStore.loadWeatherIfNeeded: \(error)")
        }

    }

    private func getLocationKey(for location: Location?) -> String? {
        location?.coordinateKey ?? locationManager.deviceClLocation?.coordinate.key
    }

}
