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
    let plannerDay: DateInRegion
    let plannerLocation: Location?
    let calendarDayData: CalendarDayData?
    let settings: PlannerSettings
    var namespace: Namespace.ID
    let openCalendarEventSheet: (EKEvent) -> Void

    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var weatherStore: WeatherStore

    private var weatherData: DayWeather? {
        weatherStore.getWeather(for: plannerDay, at: plannerLocation)
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
                calendarDayData?.birthdays ?? [],
                id: \.event.eventIdentifier,
                content: birthdayChip
            )
            ForEach(
                calendarDayData?.plannerChipEvents ?? [],
                id: \.eventIdentifier,
                content: eventChip
            )
        }
        .animateLazyAction(from: weatherData)
        .animateLazyAction(
            from: calendarDayData?.plannerChipEvents.map(\.title)
        )
        .animateLazyAction(from: locationLabel)
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

    private func birthdayChip(_ birthday: Birthday) -> some View {
        BirthdayChipView(
            birthday: birthday,
            settings: settings,
            namespace: namespace
        )
    }

    @ViewBuilder
    private func eventChip(_ event: EKEvent) -> some View {
        let calendarColor = event.calendar.color
        AdornedValue(
            event.title,
            iconConfig: IconConfig(
                name: event.calendar.systemImageName(settings: settings),
                primaryColor: calendarColor
            ),
            color: calendarColor
        )
        .glassChip(height: PlannerLayout.CHIP_HEIGHT) {
            openCalendarEventSheet(event)
        }
        .matchedTransitionSource(
            id: event.transitionId,
            in: namespace
        )
    }
}
