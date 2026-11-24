//
//  PlannerChipSpread.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
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
    let sortedChipItems: [PlannerItem]
    let sortedBirthdayItems: [PlannerBirthdayItem]
    let settings: Settings
    var namespace: Namespace.ID
    let handleItemClick: (PlannerItem) -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var plannerEngine: ListEngine<PlannerItem>

    private var locationLabel: String {
        planner.locationLabel(
            settings: settings
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
                sortedBirthdayItems,
                content: birthdayChip
            )
            ForEach(
                sortedChipItems,
                id: \.id,
                content: eventChip
            )
        }
        .animateLazyAction(
            from: sortedChipItems.map(\.title)
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
        WeatherChipView(
            planner: planner,
            settings: settings
        )
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

    private func birthdayChip(_ item: PlannerBirthdayItem) -> some View {
        BirthdayChipView(
            item: item,
            settings: settings,
            namespace: namespace
        )
    }

    @ViewBuilder
    private func eventChip(_ item: PlannerItem) -> some View {
        if let ekEvent = item.ekEvent {
            let calendarColor = ekEvent.calendarColor(accentColor: accentColor)

            let chipAccentColor =
                !plannerEngine.isSelectMode
                ? calendarColor
                : plannerEngine.selectedItemIds.contains(item.id)
                    ? accentColor.swiftUiColor : Color.secondary

            AdornedValue(
                item.title,
                iconConfig: IconConfig(
                    name: ekEvent.calendarSystemImageName(settings: settings),
                    primaryColor: chipAccentColor,
                    secondaryColor: chipAccentColor
                ),
                color: .label
            )
            .glassChip(
                color: chipAccentColor,
                height: PlannerLayout.CHIP_HEIGHT
            ) {
                handleItemClick(item)
            }
            .matchedTransitionSource(
                id: item.id,
                in: namespace
            )
        }
    }
}
