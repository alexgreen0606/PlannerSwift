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

enum PlannerPreviewType {
    case planner
    case search

    var isSoon: Bool {
        self == .planner
    }
}

struct PlannerPreviewView: View {
    private let planner: Planner
    private let type: PlannerPreviewType
    private let plannerSettings: PlannerSettings
    private let calendarSettings: CalendarSettings
    @Binding private var openPlanner: Planner?

    private let startOfDay: DateInRegion
    private let plannerRegion: Region

    private let maxPreviewEvents = 5

    init(
        planner: Planner,
        type: PlannerPreviewType,
        plannerSettings: PlannerSettings,
        calendarSettings: CalendarSettings,
        openPlanner: Binding<Planner?>
    ) {
        self.planner = planner
        self.type = type
        self.plannerSettings = plannerSettings
        self.calendarSettings = calendarSettings
        self._openPlanner = openPlanner

        let region = planner.region(settings: plannerSettings)

        guard let startOfDay = planner.datestamp.startOfDay(in: region) else {
            fatalError(
                "ERROR PlannerCardVertical.init: Could not get DateInRegion from: \(planner.datestamp)"
            )
        }

        let startOfNextDay = (startOfDay + 1.days)

        // Set the query to find this date's events.
        _plannerEvents = Query(
            filter: #Predicate<PlannerEvent> {
                $0.date >= startOfDay.date && $0.date < startOfNextDay.date
            }
        )

        self.startOfDay = startOfDay
        self.plannerRegion = region
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

    @Query private var plannerEvents: [PlannerEvent]

    @State private var calendarPlannerEvents: [PlannerEvent] = []

    var isDarkMode: Bool {
        switch appColorScheme {
        case .dark: return true
        case .light: return false
        case .system: return systemColorScheme == .dark
        }
    }

    // MARK: - Weather Data

    private var weatherData: DayWeather? {
        weatherStore.getWeather(for: planner.datestamp, at: location)
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

    // MARK: - Event Data

    private var allDayEvents: [EKEvent] {
        calendarStore.allDayEvents(for: planner)
    }

    private var sortedOpenPlannerEvents: [PlannerEvent] {
        plannerEvents
            .filter { !$0.isChecked }
            .sorted { $0.sortIndex < $1.sortIndex }
    }

    private var uncheckedCalendarPlannerEvents: [PlannerEvent] {
        calendarPlannerEvents.filter {
            !isCalendarEventChecked($0.calendarEvent)
        }
    }

    private var timedPlannerEvents: [PlannerEvent] {
        sortedOpenPlannerEvents.filter { !$0.untimed }
    }

    private var untimedPlannerEvents: [PlannerEvent] {
        sortedOpenPlannerEvents.filter { $0.untimed }
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
            + sortedOpenPlannerEvents.count

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
        sortedOpenPlannerEvents.count + allDayEvents.count
            + calendarPlannerEvents.count
            > 0
    }

    var body: some View {
        let content = VStack(alignment: .leading, spacing: 12) {
            
            HStack(alignment: .top) {
                PlannerDateInfoView(
                    datestamp: planner.datestamp,
                    region: planner.region(settings: plannerSettings),
                    isSoon: type.isSoon
                )
                
                Spacer()
                
                topRightWeatherInfo
            }

            PreviewCalendarEventListView(
                events: allDayEvents,
                iconMap: calendarSettings.iconMap
            )

            PreviewPlannerEventListView(
                plannerRegion: plannerRegion,
                events: previewPlannerEvents
            )

            remainingPlansIndicator
            emptyPlannerIndicator
            bottomWeatherInfo
        }
            .task {
                calendarStore.ensurePlannerData(
                    plannerKey: planner.key,
                    startOfDay: startOfDay,
                    hiddenCalendarIds: calendarSettings.hiddenCalendarIds
                )
            }

            // Calendar Data Tracking
            .externalData(
                key: calendarStore.loadId,
                ready: calendarStore.doesPlannerHaveData(key: planner.key),
                load: synchronizeCalendarEvents
            )

            // Weather Data Tracking
            .externalData(
                key: weatherStore.refreshKey,
                ready: true
            ) {
                Task {
                    await weatherStore.loadWeatherIfNeeded(for: location)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                openPlanner = planner
            }
        
        if type == .planner {
            content
                .padding(.top)
                .padding(.horizontal)
                .padding(.bottom, 12)
                .frame(width: 240)
                .frame(height: 330, alignment: .top)
                .background(RoundedRectangle(cornerRadius: 24)
                    .fill(Color.cardBackground))
        } else {
            content
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
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

    @ViewBuilder
    private var emptyPlannerIndicator: some View {
        if type == .planner {
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
    }

    @ViewBuilder
    private var bottomWeatherInfo: some View {
        if type == .planner {
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
                        
                        if let locationLabel {
                            HStack(spacing: 6) {
                                if weatherData == nil {
                                    Image(systemName: locationIconConfig.name)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 11, height: 11)
                                        .foregroundStyle(
                                            locationIconConfig.primaryColor
                                            ?? .secondary,
                                            locationIconConfig.secondaryColor
                                            ?? .secondary
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
    }
    
    @ViewBuilder
    // TODO: space the weather temp below the rest TEST
    private var topRightWeatherInfo: some View {
        if type == .search {
            VStack {
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
                        
                        if let locationLabel {
                            HStack(spacing: 6) {
                                if weatherData == nil, planner.location != nil {
                                    Image(systemName: locationIconConfig.name)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 11, height: 11)
                                        .foregroundStyle(
                                            locationIconConfig.primaryColor
                                            ?? .secondary,
                                            locationIconConfig.secondaryColor
                                            ?? .secondary
                                        )
                                }
                                
                                if weatherData != nil || planner.location != nil {
                                    Text(locationLabel)
                                        .foregroundStyle(
                                            Color.secondary
                                        )
                                        .font(.system(size: 10))
                                }
                            }
                        }
                    }
                }
                
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
            .animateChange(from: weatherData != nil)
            .animateChange(from: locationLabel != nil)
        }
    }

    private func synchronizeCalendarEvents() {
        calendarPlannerEvents =
            modelContext.synchronize(
                calendarEvents: calendarStore.timedEvents(for: planner),
                into: plannerEvents,
                planner: planner,
                calendarSettings: calendarSettings,
                plannerSettings: plannerSettings
            )
    }

    private func isCalendarEventChecked(_ event: EKEvent?) -> Bool {
        guard let event else {
            return false
        }

        return calendarSettings.isCalendarEventChecked(event)
    }

}
