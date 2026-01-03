//
//  PlannerChipSpreadView.swift
//  Planner
//
//  Created by Alex Green on 12/17/25.
//

import EventKit
import SwiftDate
import SwiftUI
import WrappingHStack
import WeatherKit

struct PlannerChipSpreadView: View {
    let datestamp: String
    let events: [EKEvent]
    let showCountdown: Bool
    let showWeather: Bool
    var animation: Namespace.ID?
    let openCalendarEventSheet: ((EKEvent) -> Void)?

    @AppStorage("themeColor") var themeColor: ThemeColorOption =
        ThemeColorOption.blue

    @ObservedObject var weatherStore = WeatherStore.shared
    @EnvironmentObject var calendarStore: CalendarEventStore

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
                    .transition(.opacity)
            }
            ForEach(events, id: \.eventIdentifier) { event in
                let chip = PlannerChipView(
                    title: event.title,
                    iconName: event.calendar.iconName,
                    color: Color(event.calendar.cgColor),
                    disableInteraction: openCalendarEventSheet == nil
                )

                if openCalendarEventSheet == nil || animation == nil {
                    chip
                } else {
                    chip
                        .contentShape(Rectangle())
                        .onTapGesture {
                            openCalendarEventSheet!(event)
                        }
                        .matchedTransitionSource(
                            id: String(describing: event.eventIdentifier),
                            in: animation!
                        )
                }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: weatherData != nil)
    }

    private var weather: some View {
        GlassEffectContainer {
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
                    Text(weatherData?.highTempString ?? "")
                        .font(.caption2)
                        .foregroundStyle(Color(uiColor: .label))

                    Divider().frame(height: 16)

                    Text(weatherData?.lowTempString ?? "")
                        .font(.caption2)
                        .foregroundStyle(Color(uiColor: .label))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(height: UIConstants.chipHeight)
            .glassEffect(
                in: .rect(cornerRadius: UIConstants.chipHeight / 2)
            )
        }
    }
}
