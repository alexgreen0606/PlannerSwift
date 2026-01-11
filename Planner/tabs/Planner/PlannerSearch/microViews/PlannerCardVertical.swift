//
//  PlannerCardVertical.swift
//  Planner
//
//  Created by Alex Green on 12/25/25.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI
import WeatherKit
import WrappingHStack

struct PlannerCardVerticalView: View {
    private let datestamp: String
    private let iconMap: [String: String]
    private let openPlanner: () -> Void

    private let maxPreviewEvents = 4

    @Environment(\.modelContext) private var modelContext
    @Query private var planners: [Planner]
    @State private var planner: Planner?

    @EnvironmentObject var todaystampManager: TodaystampWatcher
    @ObservedObject var weatherStore = WeatherStore.shared
    @EnvironmentObject var calendarEventStore: CalendarStore

    let unit: UnitTemperature =
        Locale.current.measurementSystem == .metric ? .celsius : .fahrenheit

    // MARK: - Weather Data

    private var weatherData: DayWeather? {
        weatherStore.dayWeatherByDatestamp[datestamp]
    }

    // MARK: - Event Data

    private var allDayEvents: [EKEvent] {
        calendarEventStore.allDayEventsByDatestamp[datestamp]
            ?? []
    }

    private var singleDayEvents: [EKEvent] {
        calendarEventStore.singleDayEventsByDatestamp[datestamp]
            ?? []
    }

    private var plannerEvents: [PlannerEvent] {
        planner?.events
            .filter { !$0.isChecked }
            .sorted { $0.sortIndex < $1.sortIndex }
            ?? []
    }

    private var previewAllDayEvents: [EKEvent] {
        Array(allDayEvents.prefix(maxPreviewEvents))
    }

    private var previewPlannerEvents: [PlannerEvent] {
        let remainingSlots = max(
            0,
            maxPreviewEvents - previewAllDayEvents.count
        )

        let singleDayPlannerEvents =
            singleDayEvents
            .prefix(remainingSlots)
            .enumerated()
            .map { index, calEvent in
                PlannerEvent(sortIndex: Double(index), calendarEvent: calEvent)
            }

        let slotsAfterSingleDay = max(
            0,
            remainingSlots - singleDayPlannerEvents.count
        )

        let plannerEventsToAdd =
            plannerEvents
            .prefix(slotsAfterSingleDay)

        return singleDayPlannerEvents + plannerEventsToAdd
    }

    private var remainingPlansLabel: String {
        let totalCount =
            allDayEvents.count + singleDayEvents.count + plannerEvents.count

        let previewCount = allDayEvents.count + previewPlannerEvents.count

        let remainingCount = totalCount - previewCount

        if remainingCount == 0 {
            if previewCount > 0 {
                return "No more plans"
            }
            return "No plans"
        }

        return "\(remainingCount) more plan\(remainingCount == 1 ? "" : "s")"
    }

    init(
        datestamp: String,
        iconMap: [String: String],
        openPlanner: @escaping () -> Void
    ) {
        self.datestamp = datestamp
        self.openPlanner = openPlanner
        self.iconMap = iconMap

        _planners = Query(
            filter: #Predicate<Planner> {
                $0.datestamp == datestamp
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PlannerDateInfoView(datestamp: datestamp, iconScale: 1.4)

            if !allDayEvents.isEmpty {
                PlannerChipSpreadView(
                    datestamp: datestamp,
                    events: previewAllDayEvents,
                    showCountdown: false,
                    showWeather: false,
                    iconMap: iconMap,
                    animation: nil,
                    openCalendarEventSheet: nil
                )
            }

            if !previewPlannerEvents.isEmpty {
                PreviewEventListView(
                    datestamp: datestamp,
                    events: previewPlannerEvents
                )
            }

            VStack {
                Text(remainingPlansLabel)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
            }
            .frame(maxHeight: .infinity)
            .frame(maxWidth: .infinity, alignment: .center)

            HStack(alignment: .bottom) {
                if weatherData != nil {
                    HStack(alignment: .center, spacing: 6) {
                        Image(systemName: weatherData?.symbolName ?? "")
                            .symbolRenderingMode(.multicolor)
                            .imageScale(.small)

                        Text(weatherData?.condition.description ?? "")
                            .font(.caption2)
                    }

                    Spacer()

                    HStack(alignment: .center, spacing: 4) {
                        Text(weatherData?.highTempString(in: unit) ?? "")
                            .font(.caption2)
                        Divider().frame(height: 16)
                        Text(weatherData?.lowTempString(in: unit) ?? "")
                            .font(.caption2)
                    }
                }
            }
            .frame(height: 16)
        }
        .padding()
        .frame(width: 220)
        .frame(height: 280, alignment: .top)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.cardBackground)
        )
        .onTapGesture(perform: openPlanner)
        .task {
            guard planner == nil else { return }

            planner = modelContext.ensurePlanner(
                planners: planners,
                datestamp: datestamp
            )
        }
    }
}
