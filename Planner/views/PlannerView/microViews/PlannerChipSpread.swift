//
//  PlannerChipSpreadView.swift
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

struct PlannerChipSpreadView: View {
    let planner: Planner
    let startOfDay: DateInRegion
    let allDayEvents: [EKEvent]
    let iconMap: [String: String]
    var namespace: Namespace.ID
    let plannerSettings: PlannerSettings
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
    @EnvironmentObject private var locationManager: DeviceLocationManager

    @State private var isLocationSheetOpen = false

    private var isDarkMode: Bool {
        switch appColorScheme {
        case .dark: return true
        case .light: return false
        case .system: return systemColorScheme == .dark
        }
    }

    private var countdownLabel: String? {
        startOfDay.countdown
    }

    private var location: Location? {
        planner.location(settings: plannerSettings)
    }

    private var locationLabel: String? {
        planner.locationLabel(
            settings: plannerSettings,
            localCityName: locationManager.cityName
        )
    }

    private var locationIconConfig: IconConfig {
        planner.locationIconConfig(
            settings: plannerSettings,
            accentColor: accentColor
        )
    }

    private var weatherData: DayWeather? {
        weatherStore.getWeather(for: startOfDay, at: location)
    }

    var body: some View {
        WrappingHStack(alignment: .leading) {

            countdownChip
            locationChip
            weatherChip

            ForEach(allDayEvents, id: \.eventIdentifier) { event in
                eventChip(event)
            }
        }
        .animateAsynchronousAction(from: weatherData)
        .animateAsynchronousAction(from: locationLabel)
        .animateAsynchronousAction(from: allDayEvents)

        // Location Sheet
        .sheet(isPresented: $isLocationSheetOpen) {
            LocationSearchView(
                initialLocation: planner.location,
                initialLocationSource: planner.locationSource,
                title: "Edit Location",
                mode: .planner
            ) { source, location in
                
                modelContext.updateLocation(
                    for: planner,
                    location: location,
                    locationSource: source
                )
                
                let newRegion = planner.region(settings: plannerSettings)
                
                Task {
                    await weatherStore.loadWeatherIfNeeded(
                        location: location,
                        region: newRegion
                    )
                }
                
            }
            .navigationTransition(
                .zoom(
                    sourceID: "LOCATION",
                    in: namespace
                )
            )
        }

        // Weather Data -> Refresh when user overscrolls.
        .externalData(
            key: weatherStore.loadTrigger,
            ready: true,
            load: loadWeather
        )
    }

    // MARK: - Chips

    @ViewBuilder
    private var countdownChip: some View {
        if let countdownLabel {
            PlannerChipView(
                title: countdownLabel,
                iconConfig: nil,
                color: nil,
                onTap: nil
            )
        }
    }

    @ViewBuilder
    private var locationChip: some View {
        if let locationLabel {
            PlannerChipView(
                title: locationLabel,
                iconConfig: locationIconConfig,
                color: nil,
                onTap: {
                    isLocationSheetOpen = true
                }
            )
            .matchedTransitionSource(
                id: "LOCATION",
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
                    Text(weatherData.highTempString(in: weatherUnit))
                        .font(
                            .system(
                                size: 11,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(Color.label)

                    Divider().frame(height: 16)

                    Text(weatherData.lowTempString(in: weatherUnit))
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
                name: iconMap[event.calendar.calendarIdentifier]
                    ?? event.calendar.iconName,
                primaryColor: nil,
                secondaryColor: nil
            ),
            color: Color(event.calendar.cgColor)
        ) {
            openCalendarEventSheet(event)
        }
        .matchedTransitionSource(
            id: event.transitionId,
            in: namespace
        )
    }

    // MARK: - Helper Function

    private func openWeatherApp() {
        guard let url = URL(string: "weather://") else { return }
        UIApplication.shared.open(url)
    }

    private func loadWeather() {
        Task {
            await weatherStore.loadWeatherIfNeeded(
                location: location,
                region: startOfDay.region
            )
        }
    }
}
