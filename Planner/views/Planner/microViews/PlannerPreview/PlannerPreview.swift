//
//  PlannerPreviewView.swift
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
    let planner: Planner
    let plannerStartOfDay: DateInRegion
    let plannerLocation: Location?
    let storageEvents: [PlannerEvent]
    let calendarPlannerEvents: [PlannerEvent]
    let calendarData: PlannerCalendarData
    let settings: PlannerSettings
    let type: PlannerPreviewType

    private let maxPreviewEvents = 5

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
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager
    @EnvironmentObject private var plannerCoverManager: PlannerCoverManager

    var isDarkMode: Bool {
        switch appColorScheme {
        case .dark: return true
        case .light: return false
        case .system: return systemColorScheme == .dark
        }
    }

    // MARK: - Weather Data

    private var weatherData: DayWeather? {
        weatherStore.getWeather(for: plannerStartOfDay, at: plannerLocation)
    }

    private var locationLabel: String? {
        planner.locationLabel(
            settings: settings,
            deviceLocation: deviceLocationManager.location
        )
    }

    private var locationIconConfig: IconConfig {
        planner.locationIconConfig(
            settings: settings,
            accentColor: accentColor
        )
    }

    // MARK: - Event Data

    private var allDayEvents: [EKEvent] {
        calendarData.allDayEvents
    }

    private var sortedOpenPlannerEvents: [PlannerEvent] {
        storageEvents
            .filter { !$0.isChecked }
            .sorted { $0.sortDate < $1.sortDate }
    }

    private var openCalendarPlannerEvents: [PlannerEvent] {
        calendarPlannerEvents.filter {
            !isCalendarEventChecked($0.calendarEvent)
        }
    }

    private var timedPlannerEvents: [PlannerEvent] {
        sortedOpenPlannerEvents.filter { $0.hasTime }
    }

    private var untimedPlannerEvents: [PlannerEvent] {
        sortedOpenPlannerEvents.filter { !$0.hasTime }
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
                openCalendarPlannerEvents
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
            .sorted { $0.sortDate < $1.sortDate }
    }

    private var remainingPlansLabel: String {
        let totalCount =
            allDayEvents.count + openCalendarPlannerEvents.count
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
            + openCalendarPlannerEvents.count
            > 0
    }

    var body: some View {
        let content = VStack(alignment: .leading, spacing: 12) {

            HStack(alignment: .top) {
                PlannerDateInfoView(
                    datestamp: planner.datestamp,
                    region: planner.region(settings: settings),
                    isSoon: type.isSoon
                )

                Spacer()

                topRightWeatherInfo
            }

            PreviewCalendarEventListView(
                events: allDayEvents,
                iconMap: settings.iconMap
            )

            PreviewPlannerEventListView(
                plannerRegion: plannerStartOfDay.region,
                events: previewPlannerEvents
            )

            remainingPlansIndicator
            emptyPlannerIndicator
            bottomWeatherInfo
        }
        .contentShape(Rectangle())
        .onTapGesture {
            plannerCoverManager.context = PlannerCoverContext(
                datestamp: planner.datestamp
            )
        }

        if type == .planner {
            content
                .padding(.top)
                .padding(.horizontal)
                .padding(.bottom, 12)
                .frame(width: 240)
                .frame(height: 330, alignment: .top)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.cardBackground)
                )
        } else {
            content
                .frame(maxWidth: .infinity)
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
                        .symbolRenderingMode(
                            isDarkMode ? .multicolor : .monochrome
                        )
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
                                            locationIconConfig.primaryColor,
                                            locationIconConfig.secondaryColor
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
                                Text(
                                    weatherData.highTempString(in: weatherUnit)
                                )
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
            .animateAsynchronousAction(from: weatherData != nil)
            .animateAsynchronousAction(from: locationLabel != nil)
        }
    }

    @ViewBuilder
    private var topRightWeatherInfo: some View {
        if type == .search {
            VStack(alignment: .trailing) {
                HStack(alignment: .bottom) {

                    VStack(alignment: .trailing, spacing: 0) {

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
                                            locationIconConfig.primaryColor,
                                            locationIconConfig.secondaryColor
                                        )
                                }

                                if weatherData != nil || planner.location != nil
                                {
                                    Text(locationLabel)
                                        .foregroundStyle(
                                            Color.secondary
                                        )
                                        .font(.system(size: 10))
                                }
                            }
                        }
                    }

                    if let weatherData {
                        Image(systemName: weatherData.symbolName)
                            .symbolVariant(isDarkMode ? .fill : .none)
                            .symbolRenderingMode(
                                isDarkMode ? .multicolor : .monochrome
                            )
                            .imageScale(.medium)
                            .frame(maxHeight: .infinity)
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
            .animateAsynchronousAction(from: weatherData != nil)
            .animateAsynchronousAction(from: locationLabel != nil)
        }
    }

    private func isCalendarEventChecked(_ event: EKEvent?) -> Bool {
        guard let event else {
            return false
        }

        return settings.isCalendarEventChecked(event)
    }

}
