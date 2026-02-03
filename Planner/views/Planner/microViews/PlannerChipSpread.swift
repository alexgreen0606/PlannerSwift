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
    let datestamp: String
    let events: [EKEvent]
    let showCountdown: Bool
    let showWeather: Bool
    let iconMap: [String: String]
    var animation: Namespace.ID?
    let openCalendarEventSheet: ((EKEvent) -> Void)?

    @ObservedObject var weatherStore = WeatherStore.shared

    let unit: UnitTemperature =
        Locale.current.measurementSystem == .metric ? .celsius : .fahrenheit

    private var daysUntil: String? {
        datestamp.date?.countdown
    }

    private var weatherData: DayWeather? {
        weatherStore.dayWeatherByDatestamp[datestamp]
    }

    var body: some View {
        WrappingHStack(alignment: .leading) {
            if showCountdown, daysUntil != nil {
                PlannerChipView(
                    title: daysUntil!,
                    iconName: nil,
                    color: Color(uiColor: .label),
                    disableInteraction: true
                )
            }
            if showWeather && weatherData != nil {
                weather
                    .contentShape(Rectangle())
                    .onTapGesture(perform: openWeatherApp)
            }
            ForEach(events, id: \.eventIdentifier) { event in
                let chip = PlannerChipView(
                    title: event.title,
                    iconName: iconMap[event.calendar.calendarIdentifier]
                        ?? event.calendar.iconName,
                    color: Color(event.calendar.cgColor),
                    disableInteraction: openCalendarEventSheet == nil
                )

                if let openCalendarEventSheet, let animation {
                    chip
                        .contentShape(Rectangle())
                        .onTapGesture {
                            openCalendarEventSheet(event)
                        }
                        .matchedTransitionSource(
                            id:
                                "\(String(describing: event.eventIdentifier))",
                            in: animation
                        )
                } else {
                    chip
                }
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
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(height: UIConstants.chipHeight)
        .glassEffect(
            .regular.interactive(),
            in: .rect(cornerRadius: UIConstants.chipHeight / 2)
        )
    }

    private func openWeatherApp() {
        guard let url = URL(string: "weather://") else { return }
        UIApplication.shared.open(url)
    }
}
