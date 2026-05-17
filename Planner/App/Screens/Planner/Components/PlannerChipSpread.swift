//
//  PlannerChipSpread.swift
//  Planner
//
//  Created by Alex Green on 12/17/25.
//

import Contacts
import ContactsUI
import EventKit
import Fuse
import SwiftData
import SwiftDate
import SwiftUI
import WeatherKit
import WrappingHStack

struct PlannerChipSpreadView: View {
    @Binding var showLocationSheet: Bool
    let planner: Planner
    let plannerDay: DateInRegion
    let weatherData: DayWeather?
    let locationLabel: String
    let calendarDayData: CalendarDayData?
    var namespace: Namespace.ID
    let settings: PlannerSettings
    let openCalendarEventSheet: (EKEvent) -> Void
    
    private let LOCATION_CHIP_ID = "LOCATION_CHIP_ID"

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var LocationService: LocationService

    @State private var contactSheetContext: Birthday? = nil

    // MARK: - Computed Variables

    private var locationIconConfig: IconConfig {
        planner.locationIconConfig(
            settings: settings,
            accentColor: accentColor
        )
    }

    // MARK: - Body

    var body: some View {
        WrappingHStack(alignment: .leading) {
            tripChip
            HStack(alignment: .top) {
                locationChip
                Spacer()
                weatherChip
            }
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

        // Location Sheet
        .sheet(isPresented: $showLocationSheet) {
            LocationSearchFormView(
                title: "Edit Planner Location",
                subtitle: planner.datestamp.dateWithYear,
                mode: .planner,
                settings: settings,
                initialLocation: planner.location,
                sourcePlanner: planner
            ) { location in
                modelContext.updatePlannerLocation(
                    for: planner,
                    to: location
                )
            }
            .navigationTransition(
                .zoom(
                    sourceID: LOCATION_CHIP_ID,
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
                planner: planner,
                settings: settings,
                namespace: namespace
            )
        }
    }

    private var locationChip: some View {
        AdornedValueView(
            locationLabel,
            iconConfig: locationIconConfig
        )
        .glassChip(height: PlannerLayout.CHIP_HEIGHT, onTap: openLocationSheet)
        .matchedTransitionSource(
            id: LOCATION_CHIP_ID,
            in: namespace
        )
    }

    @ViewBuilder
    private var weatherChip: some View {
        if let weatherData {
            WeatherChipView(weatherData: weatherData)
        }
    }

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
        .glassChip(height: PlannerLayout.CHIP_HEIGHT) {
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
