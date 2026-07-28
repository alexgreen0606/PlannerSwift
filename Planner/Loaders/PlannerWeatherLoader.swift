//
//  PlannerWeatherLoader.swift
//  Planner
//
//  Created by Alex Green on 7/20/26.
//

import SwiftData
import SwiftDate
import SwiftUI

struct PlannerWeatherLoaderView<Content: View>: View {
    let planner: Planner
    let settings: Settings
    @ViewBuilder let content: (PlannerWeather?) -> Content

    private var coordinateId: String? {
        planner.location(
            settings: settings
        )?.coordinateId
    }

    // MARK: Body

    var body: some View {
        if let coordinateId {
            PlannerWeatherQueryView(
                coordinateId: coordinateId,
                startOfDay: planner.startOfDay(
                    settings: settings
                ).date,
                content: content
            )
        } else {
            content(nil)
        }
    }
}

// MARK: - Helper View

private struct PlannerWeatherQueryView<Content: View>: View {
    @ViewBuilder private let content: (PlannerWeather?) -> Content

    init(
        coordinateId: String,
        startOfDay: Date,
        @ViewBuilder content: @escaping (PlannerWeather?) -> Content
    ) {
        self.content = content

        _forecasts = Query(
            filter: PlannerWeather.plannerWeather(
                for: startOfDay,
                coordinateId: coordinateId
            )
        )
    }

    @Query private var forecasts: [PlannerWeather]

    // MARK: Body

    var body: some View {
        content(forecasts.first)
    }
}
