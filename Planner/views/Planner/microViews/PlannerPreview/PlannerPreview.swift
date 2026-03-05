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
    let sortedPlannerEvents: [PlannerEvent]
    let allDayEvents: [EKEvent]
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

    // MARK: - Weather and Location Data

    private var weatherData: DayWeather? {
        weatherStore.getWeather(for: plannerStartOfDay, at: plannerLocation)
    }

    private var locationLabel: String? {
        planner.locationLabel(
            settings: settings,
            deviceLocation: deviceLocationManager.deviceLocation
        )
    }

    private var locationIconConfig: IconConfig {
        planner.locationIconConfig(
            settings: settings,
            accentColor: accentColor
        )
    }

    // MARK: - Event Data

    private var sortedOpenPlannerEvents: [PlannerEvent] {
        sortedPlannerEvents
            .filter { !$0.isChecked }
    }

    private var timedSortedPlannerEvents: [PlannerEvent] {
        sortedOpenPlannerEvents.filter { $0.hasTime }
    }

    private var untimedSortedPlannerEvents: [PlannerEvent] {
        sortedOpenPlannerEvents.filter { !$0.hasTime }
    }

    private var previewAllDayEvents: [EKEvent] {
        Array(allDayEvents.prefix(maxPreviewEvents))
    }

    private var sortedPreviewPlannerEvents: [PlannerEvent] {

        var previewEvents: [PlannerEvent] = []
        var remainingSlots = max(
            0,
            maxPreviewEvents - previewAllDayEvents.count - previewEvents.count
        )

        // Priority 1: Timed Storage Events
        previewEvents.append(
            contentsOf:
                timedSortedPlannerEvents
                .prefix(remainingSlots)
        )

        remainingSlots = max(
            0,
            maxPreviewEvents - previewAllDayEvents.count - previewEvents.count
        )

        // Priority 2: Untimed Storage Events
        previewEvents.append(
            contentsOf:
                untimedSortedPlannerEvents
                .prefix(remainingSlots)
        )

        return
            previewEvents
            .sorted { $0.sortDate < $1.sortDate }
    }

    private var remainingPlansLabel: String {
        let totalEventCount =
            allDayEvents.count + sortedOpenPlannerEvents.count

        let previewCount = previewAllDayEvents.count + sortedPreviewPlannerEvents.count

        let remainingCount = totalEventCount - previewCount

        if remainingCount == 0 {
            if previewCount > 0 {
                return "No more plans"
            }
            return "No plans"
        }

        return "\(remainingCount) more plan\(remainingCount == 1 ? "" : "s")"
    }

    private var hasPlans: Bool {
        (previewAllDayEvents.count + sortedPreviewPlannerEvents.count) > 0
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
                settings: settings
            )

            PreviewPlannerEventListView(
                plannerRegion: plannerStartOfDay.region,
                events: sortedPreviewPlannerEvents
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

}
