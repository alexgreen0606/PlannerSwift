//
//  PlannerChipSpread.swift
//  Planner
//
//  Created by Alex Green on 12/17/25.
//

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
    let sortedPlannerEvents: [PlannerEvent]
    let plannerChipEvents: [EKEvent]
    var namespace: Namespace.ID
    let settings: PlannerSettings
    let plannerLocation: Location?
    let openCalendarEventSheet: (EKEvent) -> Void

    let weatherUnit: UnitTemperature =
        Locale.current.measurementSystem == .metric ? .celsius : .fahrenheit

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme
        .system

    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    @State private var isLocationSheetOpen = false

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

    private var isDarkMode: Bool {
        switch appColorScheme {
        case .dark: return true
        case .light: return false
        case .system: return systemColorScheme == .dark
        }
    }

    // MARK: - Body

    var body: some View {
        WrappingHStack(alignment: .leading) {
            tripChip
            countdownChip
            locationChip
            weatherChip
            ForEach(
                plannerChipEvents,
                id: \.eventIdentifier,
                content: eventChip
            )
        }
        .animateAsynchronousAction(from: weatherData)
        .animateAsynchronousAction(from: locationLabel)
        .animateAsynchronousAction(from: plannerChipEvents.map(\.title))

        // Location Sheet
        .sheet(isPresented: $isLocationSheetOpen) {
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
    }

    // MARK: - View Builders
    
    @ViewBuilder
    private var tripChip: some View {
        if let trip = planner.trip {
            TripChipView(trip: trip, datestamp: planner.datestamp)
        }
    }
    

    @ViewBuilder
    private var countdownChip: some View {
        if !plannerDay.isNext7Days, !plannerDay.isWithinADay {
            PlannerChipView(
                title: plannerDay.countdown,
                iconConfig: nil,
                color: nil,
                onTap: nil
            )
        }
    }

    @ViewBuilder
    private var locationChip: some View {
        if planner.trip == nil {
            PlannerChipView(
                title: locationLabel,
                iconConfig: locationIconConfig,
                color: nil,
                onTap: {
                    isLocationSheetOpen = true
                }
            )
            .matchedTransitionSource(
                id: IdConstants.LOCATION_CHIP,
                in: namespace
            )
        }
    }

    @ViewBuilder
    private var weatherChip: some View {
        if let weatherData {
            HStack(alignment: .center, spacing: 8) {
                HStack(alignment: .center, spacing: 4) {
                    Image(systemName: weatherData.symbolName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .symbolVariant(isDarkMode ? .fill : .none)
                        .symbolRenderingMode(
                            isDarkMode ? .multicolor : .monochrome
                        )

                    Text(weatherData.condition.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.label)
                }

                HStack(alignment: .center, spacing: 4) {
                    Text(weatherData.highTemp(in: weatherUnit))
                        .font(
                            .system(
                                size: 11,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(Color.label)

                    Divider().frame(height: 16)

                    Text(weatherData.lowTemp(in: weatherUnit))
                        .font(
                            .system(
                                size: 10,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(Color.label)
                }
            }
            .glassChip(color: nil, onTap: openWeatherApp)
            .contentShape(Rectangle())
            .onTapGesture(perform: openWeatherApp)
        }
    }

    @ViewBuilder
    private func eventChip(_ event: EKEvent) -> some View {
        PlannerChipView(
            title: event.title,
            iconConfig: IconConfig(
                name: event.calendar.systemImageName(settings: settings),
                primaryColor: event.calendar.color
            ),
            color: event.calendar.color
        ) {
            openCalendarEventSheet(event)
        }
        .matchedTransitionSource(
            id: event.transitionId,
            in: namespace
        )
    }

    // MARK: - Functions

    private func openWeatherApp() {
        guard let url = URL(string: "weather://") else { return }
        UIApplication.shared.open(url)
    }

}
