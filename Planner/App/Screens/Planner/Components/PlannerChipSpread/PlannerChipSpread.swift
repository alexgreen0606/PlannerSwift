//
//  PlannerChipSpread.swift
//  Planner
//
//  Created by Alex Green on 12/17/25.
//

import EventKit
import SwiftDate
import SwiftUI
import WeatherKit
import WrappingHStack

struct PlannerChipSpreadView: View {
    @Binding var showLocationSheet: Bool
    let planner: Planner
    let startOfDay: DateInRegion
    let plannerLocation: Location?
    let sortedEventChips: [PlannerEvent]
    let sortedBirthdayChips: [PlannerEvent]
    let settings: PlannerSettings
    var namespace: Namespace.ID
    let openEventSheet: (PlannerEvent) -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var weatherCacheService: WeatherCacheService

    private var weatherData: DayWeather? {
        weatherCacheService.weather(for: startOfDay, at: plannerLocation)
    }

    private var locationLabel: String {
        planner.locationLabel(
            settings: settings,
            deviceLocation: locationService.deviceLocation
        )
    }

    // MARK: - Body

    var body: some View {
        WrappingHStack(alignment: .leading) {
            HStack {
                locationChip
                Spacer()
                weatherChip
            }
            tripChip
            ForEach(
                sortedBirthdayChips,
                id: \.stableId,
                content: birthdayChip
            )
            ForEach(
                sortedEventChips,
                id: \.stableId,
                content: eventChip
            )
        }
        .animateLazyAction(from: weatherData)
        .animateLazyAction(
            from: sortedEventChips.map(\.title)
        )
    }

    // MARK: - View Builders

    private var locationChip: some View {
        LocationChipView(
            showLocationSheet: $showLocationSheet,
            locationLabel: locationLabel,
            planner: planner,
            settings: settings,
            namespace: namespace
        )
    }

    @ViewBuilder
    private var weatherChip: some View {
        if let weatherData {
            WeatherChipView(weatherData: weatherData)
        }
    }

    @ViewBuilder
    private var tripChip: some View {
        if let trip = planner.trip {
            TripChipView(
                trip: trip,
                planner: planner,
                settings: settings,
                namespace: namespace
            )
        }
    }

    private func birthdayChip(_ plannerEvent: PlannerEvent) -> some View {
        BirthdayChipView(
            plannerEvent: plannerEvent,
            settings: settings,
            namespace: namespace
        )
    }

    @ViewBuilder
    private func eventChip(_ plannerEvent: PlannerEvent) -> some View {
        let calendarColor = plannerEvent.tint(accentColor: accentColor)
        AdornedValue(
            plannerEvent.title,
            iconConfig: IconConfig(
                name: plannerEvent.calendarSystemImageName(settings: settings),
                primaryColor: calendarColor,
                secondaryColor: calendarColor
            ),
            color: calendarColor
        )
        .glassChip(height: PlannerLayout.CHIP_HEIGHT) {
            openEventSheet(plannerEvent)
        }
        .matchedTransitionSource(
            id: plannerEvent.transitionId,
            in: namespace
        )
    }
}
