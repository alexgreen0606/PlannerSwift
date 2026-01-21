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
    private let isCalendarEventChecked: (EKEvent?) -> Bool
    private let openPlanner: () -> Void

    private let maxPreviewEvents = 4

    @Environment(\.modelContext) private var modelContext
    @Query private var planners: [Planner]
    @Query private var calendarSettingsList: [CalendarSettings]

    @State private var calendarPlannerEvents: [PlannerEvent] = []

    @EnvironmentObject var todaystampManager: TodaystampWatcher
    @ObservedObject var weatherStore = WeatherStore.shared
    @EnvironmentObject var calendarStore: CalendarStore

    let unit: UnitTemperature =
        Locale.current.measurementSystem == .metric ? .celsius : .fahrenheit

    private var calendarSettings: CalendarSettings? {
        calendarSettingsList.first
    }

    private var planner: Planner? {
        planners.first
    }

    // MARK: - Weather Data

    private var weatherData: DayWeather? {
        weatherStore.dayWeatherByDatestamp[datestamp]
    }

    // MARK: - Event Data

    private var allDayEvents: [EKEvent] {
        calendarStore.allDayEventsByDatestamp[datestamp]
            ?? []
    }

    private var plannerEvents: [PlannerEvent] {
        planner?.events
            .filter { !$0.isChecked }
            .sorted { $0.sortIndex < $1.sortIndex }
            ?? []
    }

    private var uncheckedCalendarPlannerEvents: [PlannerEvent] {
        calendarPlannerEvents.filter {
            !isCalendarEventChecked($0.calendarEvent)
        }
    }

    private var timedPlannerEvents: [PlannerEvent] {
        plannerEvents.filter { $0.date != nil }
    }

    private var untimedPlannerEvents: [PlannerEvent] {
        plannerEvents.filter { $0.date == nil }
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
            Array(
                uncheckedCalendarPlannerEvents
                    .prefix(remainingSlots)
            )

        let slotsAfterSingleDay = max(
            0,
            remainingSlots - singleDayPlannerEvents.count
        )

        let timedPlannerEventsToAdd =
            timedPlannerEvents
            .prefix(slotsAfterSingleDay)

        let slotsAfterTimed = max(
            0,
            remainingSlots - singleDayPlannerEvents.count
                - timedPlannerEventsToAdd.count
        )

        let untimedPlannerEventsToAdd =
            untimedPlannerEvents
            .prefix(slotsAfterTimed)

        return
            (singleDayPlannerEvents + timedPlannerEventsToAdd
            + untimedPlannerEventsToAdd)
            .sorted { $0.sortIndex < $1.sortIndex }
    }

    private var remainingPlansLabel: String {
        let totalCount =
            allDayEvents.count + uncheckedCalendarPlannerEvents.count
            + plannerEvents.count

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
        isCalendarEventChecked: @escaping (EKEvent?) -> Bool,
        openPlanner: @escaping () -> Void
    ) {
        self.datestamp = datestamp
        self.openPlanner = openPlanner
        self.iconMap = iconMap
        self.isCalendarEventChecked = isCalendarEventChecked

        _planners = Query(
            filter: #Predicate<Planner> {
                $0.datestamp == datestamp
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PlannerDateInfoView(datestamp: datestamp, isSoon: true)

            PreviewCalendarEventListView(events: allDayEvents, iconMap: iconMap)

            PreviewPlannerEventListView(
                datestamp: datestamp,
                events: previewPlannerEvents
            )

            VStack {
                Text(remainingPlansLabel)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .center
            )

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
            modelContext.ensurePlanner(
                planners: planners,
                datestamp: datestamp
            )

            modelContext.ensureCalendarSettings(
                settings: calendarSettingsList
            )

            synchronizeCalendarEvents()

        }
        .onChange(of: calendarStore.refreshKey) { _, newKey in
            synchronizeCalendarEvents()
        }
    }

    private func synchronizeCalendarEvents() {
        calendarPlannerEvents =
            modelContext.synchronize(
                calendarEvents: calendarStore.singleDayEventsByDatestamp[
                    datestamp
                ] ?? [],
                into: planner,
                with: calendarSettings
            ) ?? calendarPlannerEvents
    }

}
