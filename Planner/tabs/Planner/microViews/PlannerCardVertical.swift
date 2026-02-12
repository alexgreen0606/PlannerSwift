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
    private let isCalendarEventChecked: (EKEvent?) -> Bool
    private let openPlanner: () -> Void
    private let maxPreviewEvents = 5
    let weatherUnit: UnitTemperature =
        Locale.current.measurementSystem == .metric ? .celsius : .fahrenheit

    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme
        .system

    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.modelContext) private var modelContext
    @Query private var planners: [Planner]
    @Query private var calendarSettingsList: [CalendarSettings]
    @Query private var plannerSettingsList: [PlannerSettings]

    @ObservedObject var weatherStore = WeatherStore.shared
    @EnvironmentObject var calendarStore: CalendarStore

    @State private var calendarPlannerEvents: [PlannerEvent] = []

    private var calendarSettings: CalendarSettings? {
        calendarSettingsList.first
    }

    private var plannerSettings: PlannerSettings? {
        plannerSettingsList.first
    }

    private var planner: Planner? {
        planners.first
    }

    var isDarkMode: Bool {
        switch appColorScheme {
        case .dark: return true
        case .light: return false
        case .system: return systemColorScheme == .dark
        }
    }

    // MARK: - Weather Data

    private var weatherData: DayWeather? {
        weatherStore.getWeather(for: datestamp, at: location)
    }

    private var location: Location? {
        planner?.location(settings: plannerSettings)
    }

    private var locationLabel: String? {
        planner?.locationLabel(
            settings: plannerSettings,
            localCityName: weatherStore.locationManager.cityName
        )
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

    private var hasPlans: Bool {
        plannerEvents.count + allDayEvents.count + calendarPlannerEvents.count
            > 0
    }

    init(
        datestamp: String,
        isCalendarEventChecked: @escaping (EKEvent?) -> Bool,
        openPlanner: @escaping () -> Void
    ) {
        self.datestamp = datestamp
        self.openPlanner = openPlanner
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

            PreviewCalendarEventListView(
                events: allDayEvents,
                iconMap: calendarSettings?.iconMap
            )

            PreviewPlannerEventListView(
                datestamp: datestamp,
                events: previewPlannerEvents,
                hideLastDivider: false
            )

            remainingPlansIndicator
            emptyPlannerIndicator
            weatherInfo
        }
        .padding(.horizontal)
        .padding(.top)
        .padding(.bottom, 6)
        .frame(width: 240)
        .frame(height: 330, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.cardBackground)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: openPlanner)

        // Load in the planner and calendar settings.
        .task {
            modelContext.ensurePlanner(
                planners: planners,
                datestamp: datestamp
            )

            modelContext.ensureCalendarSettings(
                settings: calendarSettingsList
            )

            modelContext.ensurePlannerSettings(
                settings: plannerSettingsList
            )
        }

        // Calendar Data Tracking
        .externalData(
            key: calendarStore.refreshKey,
            ready: planner != nil && calendarSettings != nil,
            load: synchronizeCalendarEvents
        )

        // Weather Data Tracking
        .externalData(
            key: weatherStore.refreshKey,
            ready: planner != nil && plannerSettings != nil
        ) {
            Task {
                await weatherStore.loadWeatherIfNeeded(for: location)
            }
        }
    }

    @ViewBuilder
    private var remainingPlansIndicator: some View {
        if hasPlans {
            Text(remainingPlansLabel)
                .font(
                    .system(size: 12, weight: .heavy, design: .rounded)
                )
                .foregroundStyle(Color(uiColor: .secondaryLabel))
        }
    }

    private var emptyPlannerIndicator: some View {
        VStack {
            if !hasPlans {
                Text(remainingPlansLabel)
                    .font(
                        .system(size: 12, weight: .heavy, design: .rounded)
                    )
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .center
        )
    }

    @ViewBuilder
    private var weatherInfo: some View {
        HStack {
            if let weatherData, let locationLabel {
                Image(systemName: weatherData.symbolName)
                    .symbolVariant(isDarkMode ? .fill : .none)
                    .symbolRenderingMode(isDarkMode ? .multicolor : .monochrome)
                    .imageScale(.medium)

                VStack(alignment: .leading, spacing: 0) {
                    Text(weatherData.condition.description)
                        .font(.system(size: 12, design: .rounded))

                    HStack {
                        Text(locationLabel)
                            .foregroundStyle(
                                Color(uiColor: .secondaryLabel)
                            )
                            .font(.system(size: 10))

                        Spacer()

                        HStack(alignment: .center, spacing: 4) {
                            Text(weatherData.highTempString(in: weatherUnit))
                                .font(
                                    .system(
                                        size: 11,
                                        weight: .bold,
                                        design: .rounded
                                    )
                                )
                            Divider().frame(height: 16)
                            Text(weatherData.lowTempString(in: weatherUnit))
                                .font(
                                    .system(
                                        size: 10,
                                        weight: .bold,
                                        design: .rounded
                                    )
                                )
                        }
                    }
                }
            }
        }
        .frame(height: 40)
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
