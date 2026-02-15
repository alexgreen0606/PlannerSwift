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

    @Published private var weatherMap: [String: [String: DayWeather]] =
        [:]

    @Published var refreshKey: UUID = UUID()

    func getWeather(for datestamp: String, at location: Location?)
        -> DayWeather?
    {
        guard let locationKey = getLocationKey(for: location) else {
            return nil
        }

        return weatherMap[locationKey]?[datestamp]
    }

    func getLocationKey(for location: Location?) -> String? {
        let coordinate: CLLocationCoordinate2D?

        if let location {
            coordinate = CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            )
        } else {
            coordinate = locationManager.deviceClLocation?.coordinate
        }

        guard let coordinate else { return nil }

        let lat = coordinate.latitude.roundDecimals(to: 4)
        let lon = coordinate.longitude.roundDecimals(to: 4)

        return "\(lat),\(lon)"
    }

    func resetWeather() async {
        await loadWeatherIfNeeded(for: nil, clearCache: true)
        refreshKey = UUID()
    }

    func loadWeatherIfNeeded(
        for location: Location?,
        clearCache: Bool = false
    ) async {
        let weatherLocation: CLLocation

        guard let locationKey = getLocationKey(for: location) else {
            print("No location available.")
            return
        }

        if weatherMap[locationKey] != nil, !clearCache {
            // Weather already loaded. Exit early.
            return
        } else {
            weatherMap[locationKey] = [:]
        }

        if let location {
            weatherLocation = CLLocation(
                latitude: location.latitude,
                longitude: location.longitude
            )
        } else if let deviceLocation = locationManager.deviceClLocation {
            weatherLocation = deviceLocation
        } else {
            print("Unable to determine location.")
            return
        }

        do {
            let weather = try await weatherService.weather(for: weatherLocation)

            var newMap = clearCache ? [:] : weatherMap

            for dayWeather in weather.dailyForecast {
                let datestamp = "TODO" // dayWeather.date.datestamp // TODO: cast to DateInRegion as needed
                newMap[locationKey, default: [:]][datestamp] = dayWeather
            }

            weatherMap = newMap
        } catch {
            print("Failed to load weather: \(error)")
        }

    }

}
