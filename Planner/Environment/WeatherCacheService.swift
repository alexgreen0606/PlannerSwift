//
//  WeatherCacheService.swift
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
final class WeatherCacheService: ObservableObject {
    init(locationService: LocationService) {
        self.locationService = locationService
    }
    
    private let locationService: LocationService
    
    private let weatherService = WeatherService()

    /// Location Key -> [Planner Start of Day -> Weather]
    private var weatherCache: [String: [Date: DayWeather]] = [:]
    
    private var loadedLocationKeys: Set<String> = []

    @Published private(set) var reloadTrigger: UUID?

    func beginReload() {
        loadedLocationKeys.removeAll()
        reloadTrigger = UUID()
    }

    func weather(for startOfDay: DateInRegion, at location: Location?)
        -> DayWeather?
    {
        guard let locationKey = locationKey(for: location) else {
            return nil
        }

        return weatherCache[locationKey]?[startOfDay.date]
    }

    func ensureWeather(
        location: Location?,
        region: Region
    ) async {
        guard let locationKey = locationKey(for: location) else {
            return
        }

        // MARK: Priority 1: Return cached weather for this day/location.
        
        if loadedLocationKeys.contains(locationKey) {
            return
        } else {
            loadedLocationKeys.insert(locationKey)
        }
        
        // MARK: Get the location needed for the weather API.

        let weatherLocation: CLLocation

        if let location {
            weatherLocation = CLLocation(
                latitude: location.latitude,
                longitude: location.longitude
            )
        } else if let deviceLocation = locationService.deviceClLocation {
            weatherLocation = deviceLocation
        } else {
            return
        }
        
        // MARK: Load in the weather for this location.

        do {
            let weather = try await weatherService.weather(for: weatherLocation)

            // Assemble a map of weather for every available day in this location.
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
            print("ERROR WeatherCacheService.ensureWeather: \(error)")
        }
    }

    // MARK: - Helper Function

    private func locationKey(for location: Location?) -> String? {
        location?.coordinateKey
            ?? locationService.deviceClLocation?.coordinate.key
    }
}
