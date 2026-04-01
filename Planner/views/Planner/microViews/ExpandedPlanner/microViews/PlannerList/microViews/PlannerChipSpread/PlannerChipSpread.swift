//
//  PlannerChipSpread.swift
//  Planner
//
//  Created by Alex Green on 12/17/25.
//

import Contacts
import ContactsUI
import EventKit
import SwiftData
import SwiftDate
import SwiftUI
import WeatherKit
import WrappingHStack

// Clean

struct PlannerChipSpreadView: View {
    let planner: Planner
    let plannerDay: DateInRegion
    let plannerLocation: Location?
    let calendarDayData: CalendarDayData
    let sortedPlannerEvents: [PlannerEvent]
    var namespace: Namespace.ID
    let settings: PlannerSettings
    let openCalendarEventSheet: (EKEvent) -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    @State private var showLocationSheet = false
    @State private var contactSheetContext: Birthday? = nil

    // MARK: - Computed Variables

    private var locationLabel: String {
        planner.locationLabel(
            settings: settings,
            deviceLocation: deviceLocationManager.deviceLocation
        )
    }

    private var locationIconConfig: IconConfig {
        planner.locationIconConfig(
            settings: settings,
            accentColor: accentColor
        )
    }

    private var weatherData: DayWeather? {
        weatherStore.getWeather(for: plannerDay, at: plannerLocation)
    }

    // MARK: - Body

    var body: some View {
        WrappingHStack(alignment: .leading) {
            tripChip
            locationChip
            weatherChip
            ForEach(
                calendarDayData.birthdays,
                id: \.event.eventIdentifier,
                content: birthdayChip
            )
            ForEach(
                calendarDayData.plannerChipEvents,
                id: \.eventIdentifier,
                content: eventChip
            )
        }
        .animateAsynchronousAction(from: weatherData)
        .animateAsynchronousAction(from: locationLabel)
        .animateAsynchronousAction(
            from: calendarDayData.plannerChipEvents.map(\.title)
        )

        // Location Sheet
        .sheet(isPresented: $showLocationSheet) {
            LocationSearchFormView(
                title: "Planner Location",
                mode: .planner,
                settings: settings,
                initialLocation: planner.location,
                sourcePlanner: planner,
            ) { location in
                modelContext.updatePlannerLocation(
                    for: planner,
                    to: location,
                    settings: settings,
                    storageEvents: sortedPlannerEvents
                )
            }
            .navigationTransition(
                .zoom(
                    sourceID: IdConstants.LOCATION_CHIP,
                    in: namespace
                )
            )
        }

        // Contact Sheet
        .sheet(item: $contactSheetContext) { context in
            ContactFormView(contact: context.contact)
                .ignoresSafeArea()
                .navigationTransition(
                    .zoom(
                        sourceID: context.event.transitionId,
                        in: namespace
                    )
                )
        }

    }

    // MARK: - View Builders

    @ViewBuilder
    private var tripChip: some View {
        if let trip = planner.trip {
            TripChipView(
                trip: trip,
                datestamp: planner.datestamp,
                settings: settings
            )
        }
    }

    @ViewBuilder
    private var locationChip: some View {
        if planner.trip == nil {
            AdornedValueView(
                locationLabel,
                iconConfig: locationIconConfig
            )
            .glassChip(onTap: openLocationSheet)
            .matchedTransitionSource(
                id: IdConstants.LOCATION_CHIP,
                in: namespace
            )
        }
    }

    @ViewBuilder
    private var weatherChip: some View {
        if let weatherData {
            WeatherChipView(weatherData: weatherData)
        }
    }

    @ViewBuilder
    private func birthdayChip(_ birthday: Birthday) -> some View {
        BirthdayChipView(
            birthday: birthday,
            settings: settings,
            openContactSheet: openContactSheet
        )
        .matchedTransitionSource(
            id: birthday.event.transitionId,
            in: namespace
        )
    }

    @ViewBuilder
    private func eventChip(_ event: EKEvent) -> some View {
        let calendarColor = event.calendar.color
        AdornedValueView(
            event.title,
            color: calendarColor,
            iconConfig: IconConfig(
                name: event.calendar.systemImageName(settings: settings),
                primaryColor: calendarColor
            )
        )
        .glassChip(color: calendarColor) {
            openCalendarEventSheet(event)
        }
        .matchedTransitionSource(
            id: event.transitionId,
            in: namespace
        )
    }

    // MARK: - Functions

    private func openContactSheet(for birthday: Birthday) {
        contactSheetContext = birthday
    }

    private func openLocationSheet() {
        showLocationSheet = true
    }

}
