//
//  WeatherPreview.swift
//  Planner
//
//  Created by Alex Green on 5/12/26.
//

import SwiftDate
import SwiftUI
import WeatherKit

struct WeatherPreviewView: View {
    let planner: Planner
    let startAdorned: Bool
    let showLocationLabel: Bool
    let plannerDay: DateInRegion
    let plannerLocation: Location?
    let settings: PlannerSettings

    init(
        planner: Planner,
        startAdorned: Bool = true,
        showLocationLabel: Bool,
        plannerDay: DateInRegion,
        plannerLocation: Location?,
        settings: PlannerSettings
    ) {
        self.planner = planner
        self.startAdorned = startAdorned
        self.showLocationLabel = showLocationLabel
        self.plannerDay = plannerDay
        self.plannerLocation = plannerLocation
        self.settings = settings
    }

    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme
        .dark

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.colorScheme) private var systemColorScheme
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var LocationService: LocationService

    private var weatherData: DayWeather? {
        weatherStore.getWeather(
            for: plannerDay,
            at: plannerLocation
        )
    }

    private var locationLabel: String {
        planner.locationLabel(
            settings: settings,
            deviceLocation: LocationService.deviceLocation
        )
    }

    private var locationIconConfig: IconConfig? {
        guard weatherData == nil else {
            return nil
        }
        return planner.locationIconConfig(
            settings: settings,
            accentColor: accentColor
        )
    }

    var isDarkMode: Bool {
        switch appColorScheme {
        case .dark: return true
        case .light: return false
        case .system: return systemColorScheme == .dark
        }
    }

    var body: some View {
        HStack {
            if startAdorned, let weatherData {
                Image(systemName: weatherData.symbolName)
                    .symbolVariant(isDarkMode ? .fill : .none)
                    .symbolRenderingMode(
                        isDarkMode ? .multicolor : .monochrome
                    )
                    .imageScale(.medium)
                    .frame(maxHeight: .infinity)
            }

            VStack(alignment: startAdorned ? .leading : .trailing, spacing: 0) {

                if let weatherData {
                    TemperatureView(weatherData: weatherData)
                }

                if showLocationLabel {
                    HStack(spacing: 6) {
                        if let locationIconConfig {
                            Image(systemName: locationIconConfig.name)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 11, height: 11)
                                .foregroundStyle(
                                    locationIconConfig.primaryColor,
                                    locationIconConfig.secondaryColor
                                )
                        }

                        if showLocationLabel {
                            Text(locationLabel)
                                .foregroundStyle(
                                    Color.secondary
                                )
                                .font(.system(size: 10))
                        }
                    }
                }
            }

            if !startAdorned, let weatherData {
                Image(systemName: weatherData.symbolName)
                    .symbolVariant(isDarkMode ? .fill : .none)
                    .symbolRenderingMode(
                        isDarkMode ? .multicolor : .monochrome
                    )
                    .imageScale(.medium)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(height: 30)
        .animateAsynchronousAction(from: weatherData)
        //        HStack(alignment: .bottom) {
        //            if let weatherData {
        //                Image(systemName: weatherData.symbolName)
        //                    .symbolVariant(isDarkMode ? .fill : .none)
        //                    .symbolRenderingMode(
        //                        isDarkMode ? .multicolor : .monochrome
        //                    )
        //                    .imageScale(.medium)
        //                    .frame(maxHeight: .infinity)
        //            }
        //
        //            VStack(alignment: .leading, spacing: 0) {
        //
        //                if let weatherData {
        //                    Text(weatherData.condition.description)
        //                        .font(.system(size: 12, design: .rounded))
        //                }
        //
        //                HStack {
        //
        //                    AdornedValueView(
        //                        locationLabel,
        //                        color: Color.secondary,
        //                        iconConfig: locationIconConfig,
        //                        scale: 0.7
        //                    )
        //
        //                    Spacer()
        //
        //                    if let weatherData {
        //                        TemperatureView(weatherData: weatherData)
        //                    }
        //                }
        //                .frame(maxHeight: .infinity, alignment: .bottom)
        //            }
        //        }
        //        .frame(height: 30)
        //        .animateAsynchronousAction(from: weatherData)
    }

}
