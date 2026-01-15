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
    @Query private var calendarSettingsList: [CalendarSettings]
    @State private var planner: Planner?
    @State private var calendarSettings: CalendarSettings?

    @State private var calendarPlannerEvents: [PlannerEvent] = []

    @EnvironmentObject var todaystampManager: TodaystampWatcher
    @ObservedObject var weatherStore = WeatherStore.shared
    @EnvironmentObject var calendarStore: CalendarStore

    let unit: UnitTemperature =
        Locale.current.measurementSystem == .metric ? .celsius : .fahrenheit

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

    private var previewAllDayEvents: [EKEvent] {
        Array(allDayEvents.prefix(maxPreviewEvents))
    }

    private var previewPlannerEvents: [PlannerEvent] {
        let remainingSlots = max(
            0,
            maxPreviewEvents - previewAllDayEvents.count
        )

        let singleDayPlannerEvents =
            Array(calendarPlannerEvents
            .prefix(remainingSlots))

        let slotsAfterSingleDay = max(
            0,
            remainingSlots - singleDayPlannerEvents.count
        )

        let plannerEventsToAdd =
            plannerEvents
            .prefix(slotsAfterSingleDay)

        return (singleDayPlannerEvents + plannerEventsToAdd)
                .sorted { $0.sortIndex < $1.sortIndex }
    }

    private var remainingPlansLabel: String {
        let totalCount =
            allDayEvents.count + calendarPlannerEvents.count + plannerEvents.count

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
            PlannerDateInfoView(datestamp: datestamp)

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
            planner = modelContext.ensurePlanner(
                planners: planners,
                datestamp: datestamp
            )

            calendarSettings = modelContext.ensureCalendarSettings(
                settings: calendarSettingsList
            )

            synchronizeCalendarEvents()
        }
    }

    private func synchronizeCalendarEvents() {
        guard let planner = planner, let settings = calendarSettings
        else { return }
        let calendarStoreEvents =
            calendarStore.singleDayEventsByDatestamp[datestamp] ?? []

        calendarPlannerEvents =
            planner.synchronizeCalendarEventPositions(
                for: calendarStoreEvents,
                from: settings
            )

        try! modelContext.save()
    }

}
