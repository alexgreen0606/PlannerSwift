//
//  PlannerChipSpreadView.swift
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
    let planner: Planner
    let iconMap: [String: String]
    var animation: Namespace.ID
    let openCalendarEventSheet: (EKEvent) -> Void
    let openLocationSheet: () -> Void
    let weatherUnit: UnitTemperature =
        Locale.current.measurementSystem == .metric ? .celsius : .fahrenheit

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme
        .system

    @Environment(\.colorScheme) private var systemColorScheme

    @EnvironmentObject var calendarStore: CalendarStore
    @ObservedObject var weatherStore = WeatherStore.shared

    var isDarkMode: Bool {
        switch appColorScheme {
        case .dark: return true
        case .light: return false
        case .system: return systemColorScheme == .dark
        }
    }

    private var countdownLabel: String? {
        planner.datestamp.date?.countdown
    }

    private var locationLabel: String? {
        planner.location?.name
            ?? weatherStore.locationManager.cityName
    }

    private var weatherData: DayWeather? {
        weatherStore.getWeather(for: planner.datestamp, at: planner.location)
    }

    private var allDayEvents: [EKEvent] {
        calendarStore.allDayEventsByDatestamp[
            planner.datestamp
        ] ?? []
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
        .animation(.spring, value: weatherData)
        .animation(.spring, value: locationLabel)
        .animation(.spring, value: allDayEvents)
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
                iconConfig: IconConfig(
                    name: planner.location != nil
                        ? "mappin.and.ellipse" : "location",
                    primaryColor: accentColor.swiftUIColor,
                    secondaryColor: Color(uiColor: .secondaryLabel)
                ),
                color: nil,
                onTap: openLocationSheet
            )
            .matchedTransitionSource(
                id: "LOCATION",
                in: animation
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
                        .foregroundStyle(Color(uiColor: .label))
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
                        .foregroundStyle(Color(uiColor: .label))

                    Divider().frame(height: 16)

                    Text(weatherData.lowTempString(in: weatherUnit))
                        .font(
                            .system(
                                size: 10,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(Color(uiColor: .label))
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
            in: animation
        )
    }

    // MARK: - Helper Function

    private func openWeatherApp() {
        guard let url = URL(string: "weather://") else { return }
        UIApplication.shared.open(url)
    }
}
