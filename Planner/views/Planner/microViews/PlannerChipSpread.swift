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

    @EnvironmentObject var calendarStore: CalendarStore
    @ObservedObject var weatherStore = WeatherStore.shared

    let unit: UnitTemperature =
        Locale.current.measurementSystem == .metric ? .celsius : .fahrenheit

    private var daysUntil: String? {
        planner.datestamp.date?.countdown
    }

    private var allDayEvents: [EKEvent] {
        calendarStore.allDayEventsByDatestamp[
            planner.datestamp
        ] ?? []
    }

    private var weatherData: DayWeather? {
        weatherStore.getWeather(for: planner.datestamp, at: planner.location)
    }

    var body: some View {
        WrappingHStack(alignment: .leading) {
            
            // Countdown Chip
            if let daysUntil {
                PlannerChipView(
                    title: daysUntil,
                    iconName: nil,
                    color: nil,
                    onTap: nil
                )
            }
            
            // Location Chip
            PlannerChipView(
                title: planner.location?.name
                    ?? weatherStore.locationManager.cityName,
                iconName: planner.location != nil ? "mappin.and.ellipse" : "location",
                color: nil,
                onTap: openLocationSheet
            )
            .matchedTransitionSource(
                id:
                    "LOCATION",
                in: animation
            )

            // Weather Chip
            if weatherData != nil {
                weather
                    .contentShape(Rectangle())
                    .onTapGesture(perform: openWeatherApp)
            }
            
            // Event Chips
            ForEach(allDayEvents, id: \.eventIdentifier) { event in
                PlannerChipView(
                    title: event.title,
                    iconName: iconMap[event.calendar.calendarIdentifier]
                        ?? event.calendar.iconName,
                    color: Color(event.calendar.cgColor)
                ) {
                    openCalendarEventSheet(event)
                }
                .matchedTransitionSource(
                    id:
                        "\(String(describing: event.eventIdentifier))",
                    in: animation
                )
            }
        }
        .animation(.easeInOut(duration: 0.5), value: weatherData != nil)
    }

    private var weather: some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(alignment: .center, spacing: 4) {
                Image(systemName: weatherData!.symbolName)
                    .symbolRenderingMode(.multicolor)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)

                Text(weatherData!.condition.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(uiColor: .label))
            }

            HStack(alignment: .center, spacing: 4) {
                Text(weatherData?.highTempString(in: unit) ?? "")
                    .font(.caption2)
                    .foregroundStyle(Color(uiColor: .label))

                Divider().frame(height: 16)

                Text(weatherData?.lowTempString(in: unit) ?? "")
                    .font(.caption2)
                    .foregroundStyle(Color(uiColor: .label))
            }
        }
        .glassChip(color: nil, onTap: openWeatherApp)
    }

    private func openWeatherApp() {
        guard let url = URL(string: "weather://") else { return }
        UIApplication.shared.open(url)
    }
}
