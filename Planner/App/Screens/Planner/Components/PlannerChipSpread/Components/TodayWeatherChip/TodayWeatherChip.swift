//
//  TodayWeatherChip.swift
//  Planner
//
//  Created by Alex Green on 10/2/26.
//

import SwiftUI
import WeatherKit

struct TodayWeatherChipView: View {
    let planner: Planner
    let settings: Settings

    private let weatherUnit: UnitTemperature =
        Locale.current.measurementSystem == .metric ? .celsius : .fahrenheit

    private let ICON_SIZE: CGFloat = 17

    private let images = [
        "sun.max.fill",
        "sun.max.fill",
        "cloud.fill",
        "cloud.fill",
        "cloud.rain.fill",
        "sun.max.fill",
        "sun.max.fill",
        "cloud.fill",
        "cloud.fill",
        "cloud.rain.fill",
    ]

    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme
        .dark

    @Environment(\.colorScheme) private var systemColorScheme
    @EnvironmentObject private var plannerEngine: ListEngine<PlannerEvent>

    private var isDarkMode: Bool {
        switch appColorScheme {
        case .dark: return true
        case .light: return false
        case .system: return systemColorScheme == .dark
        }
    }

    // MARK: - Body

    var body: some View {
        PlannerWeatherLoaderView(
            planner: planner,
            settings: settings
        ) { plannerWeather in
            if let plannerWeather {
                ZStack {
                    TodayWeatherChipContainerView()

                    HStack(alignment: .top) {

                        //                        HStack(spacing: 12) {
                        //                            ForEach(Array(images.enumerated()), id: \.offset) {
                        //                                idx,
                        //                                image in
                        //                                VStack {
                        //                                    Image(systemName: image)
                        //                                        .symbolRenderingMode(.multicolor)
                        //                                        .font(.system(size: 12))
                        //                                }
                        //                            }
                        //                        }
                        //                        .frame(height: PlannerLayout.CHIP_HEIGHT)

                        Spacer()

                        Image(systemName: "sun.max.fill")
                            .symbolRenderingMode(.multicolor)
                            .font(.system(size: 12))
                        
                        Text("Mostly Sunny")

                        let measurement = Measurement(
                            value: plannerWeather.highTemp,
                            unit: UnitTemperature.fahrenheit
                        )

                        let converted = measurement.converted(to: weatherUnit)

                        ZStack {
                            Gauge(
                                value: plannerWeather.highTemp - 5,
                                in: plannerWeather
                                    .lowTemp...plannerWeather.highTemp,
                                label: {}
                            )
                            .gaugeStyle(.accessoryCircular)

                            Text("\(Int(converted.value.rounded()))°")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .scaleEffect(0.7, anchor: .trailing)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}
