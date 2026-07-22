//
//  ModelContext+PlannerWeather.swift
//  Planner
//
//  Created by Alex Green on 7/17/26.
//

import CoreLocation
import Foundation
import SwiftData
import SwiftDate
import WeatherKit

extension ModelContext {
    // MARK: - CREATE

    private func createPlannerWeather(
        for dayWeather: DayWeather,
        at location: Location,
        on startOfDay: Date
    ) {
        insert(
            PlannerWeather(
                coordinateId: location.coordinateId,
                startOfDay: startOfDay,
                dayWeather: dayWeather
            )
        )

        // Note: Don't save the context here. It is part of a larger pipeline.
    }

    // MARK: - READ

    func getPlannerWeather(
        for startOfDay: Date,
        at coordinateId: String
    )
        -> PlannerWeather?
    {
        do {
            return try fetch(
                FetchDescriptor<PlannerWeather>(
                    predicate: PlannerWeather.plannerWeather(
                        for: startOfDay,
                        coordinateId: coordinateId
                    ),
                    sortBy: [
                        SortDescriptor(
                            \PlannerWeather.fetchedAt,
                            order: .reverse
                        )
                    ]
                )
            ).first
        } catch {
            assertionFailure(
                "ERROR ModelContext+WeathertForecast getPlannerWeather: \(error)"
            )
        }

        return nil
    }

    // MARK: - Synchronization

    func syncWeather(
        location: Location,
        startOfDay: DateInRegion,
        weatherService: WeatherService
    ) async {
        let coordinateId = location.coordinateId
        let region = startOfDay.region
        let clLocation = CLLocation(
            latitude: location.latitude,
            longitude: location.longitude
        )

        // Load in the weather for this location.

        var weather: Weather

        do {
            weather = try await weatherService.weather(for: clLocation)
        } catch {
            print("ERROR ModelContext+PlannerWeather syncWeather: \(error)")
            return
        }

        // Sync the weather data for each day in the response.

        for dayWeather in weather.dailyForecast {
            let startOfDay = DateInRegion(
                dayWeather.date,
                region: region
            )
            .dateAtStartOf(.day)
            .date

            if let existing = getPlannerWeather(
                for: startOfDay,
                at: coordinateId
            ) {
                existing.syncWithDayWeather(dayWeather)
            } else {
                createPlannerWeather(
                    for: dayWeather,
                    at: location,
                    on: startOfDay.date
                )
            }
        }

        safeSave("ModelContext+PlannerWeather syncWeather")
    }
}
