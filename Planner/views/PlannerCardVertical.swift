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
    @Binding private var openPlanner: Planner?
    // private let openPlanner: () -> Void
    private let maxPreviewEvents = 5
    
    init(
        datestamp: String,
        openPlanner: Binding<Planner?>
        // openPlanner: @escaping () -> Void
    ) {
        self.datestamp = datestamp
        self._openPlanner = openPlanner

        _planners = Query(
            filter: #Predicate<Planner> {
                $0.datestamp == datestamp
            }
        )
    }
    
    let weatherUnit: UnitTemperature =
        Locale.current.measurementSystem == .metric ? .celsius : .fahrenheit

    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme
        .system
    
    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var locationManager: DeviceLocationManager
    
    @Query private var planners: [Planner]
    @Query private var calendarSettingsList: [CalendarSettings]
    @Query private var plannerSettingsList: [PlannerSettings]

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
            localCityName: locationManager.cityName
        )
    }
    
    private var locationIconConfig: IconConfig? {
        planner?.locationIconConfig(
            settings: plannerSettings,
            accentColor: accentColor
        )
    }

    // MARK: - Event Data

    private var allDayEvents: [EKEvent] {
        calendarStore.allDayEventsByDatestamp[datestamp]
            ?? []
    }

    private var plannerEvents: [PlannerEvent] {
        []
        // TODO: fix this
//        planner?.events
//            .filter { !$0.isChecked }
//            .sorted { $0.sortIndex < $1.sortIndex }
//            ?? []
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // TODO: use correct value here for region
            PlannerDateInfoView(datestamp: datestamp, region: .local, isSoon: true)

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
        .padding(.bottom, 12)
        .frame(width: 240)
        .frame(height: 330, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.cardBackground)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if let planner {
                openPlanner = planner
            }
        }

        // Load in the planner and calendar settings.
        .task {
            modelContext.ensurePlanner(
                planners: planners,
                datestamp: datestamp
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
                .foregroundStyle(Color.secondary)
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
        HStack(alignment: .bottom) {
            if let weatherData {
                Image(systemName: weatherData.symbolName)
                    .symbolVariant(isDarkMode ? .fill : .none)
                    .symbolRenderingMode(isDarkMode ? .multicolor : .monochrome)
                    .imageScale(.medium)
                    .frame(maxHeight: .infinity)
            }

            VStack(alignment: .leading, spacing: 0) {

                if let weatherData {
                    Text(weatherData.condition.description)
                        .font(.system(size: 12, design: .rounded))
                }

                HStack {

                    if let locationLabel, let locationIconConfig {
                        HStack(spacing: 6) {
                            if weatherData == nil {
                                Image(systemName: locationIconConfig.name)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 11, height: 11)
                                    .foregroundStyle(
                                        locationIconConfig.primaryColor ?? .secondary,
                                        locationIconConfig.secondaryColor ?? .secondary
                                    )
                            }
                            
                            Text(locationLabel)
                                .foregroundStyle(
                                    Color.secondary
                                )
                                .font(.system(size: 10))
                        }
                    }

                    Spacer()

                    if let weatherData {
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
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .frame(height: 30)
        .animateChange(from: weatherData != nil)
        .animateChange(from: locationLabel != nil)
    }

    private func synchronizeCalendarEvents() {
        guard let planner, let calendarSettings, let plannerSettings else {
            return
        }
        
        // TODO: pass correct events
        calendarPlannerEvents =
            modelContext.synchronize(
                calendarEvents: calendarStore.singleDayEventsByDatestamp[
                    datestamp
                ] ?? [],
                into: [],
                planner: planner,
                calendarSettings: calendarSettings,
                plannerSettings: plannerSettings
            ) ?? calendarPlannerEvents
    }

    private func isCalendarEventChecked(_ event: EKEvent?) -> Bool {
        guard let calendarSettings, let event else {
            return false
        }

        return calendarSettings.checkedCalendarEventIds.contains(
            event.calendarItemExternalIdentifier
        )
    }

}
