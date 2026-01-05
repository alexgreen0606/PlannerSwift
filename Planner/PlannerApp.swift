//
//  PlannerApp.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftData
import SwiftUI

enum ThemeColorOption: String, Codable, CaseIterable {
    case red
    case orange
    case yellow
    case green
    case blue
    case indigo
    case purple

    var swiftUIColor: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .indigo: return .indigo
        case .purple: return .purple
        }
    }

    var label: String {
        rawValue.capitalized
    }
}

@main
struct PlannerApp: App {
    @AppStorage("themeColor") var themeColor: ThemeColorOption =
        ThemeColorOption.blue

    @Environment(\.modelContext) private var modelContext
    @Query private var calendarSettingsList: [CalendarSettings]

    let calendarStore = CalendarEventStore.shared
    let weatherStore = WeatherStore.shared

    @StateObject private var navigationManager = NavigationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .accentColor(themeColor.swiftUIColor)
                .environmentObject(TodaystampWatcher.shared)
                .environmentObject(weatherStore)
                .environmentObject(calendarStore)
                .environmentObject(navigationManager)
                .onAppear {
                    let calendarSettings = modelContext.ensureCalendarSettings(
                        settings: calendarSettingsList
                    )

                    calendarStore.requestAccessAndLoadIfNeeded(
                        hiddenCalendarIds: calendarSettings.hiddenCalendarIds
                    )

                    Task {
                        await weatherStore.loadWeather()
                    }
                }
        }
        .modelContainer(for: [
            Planner.self, ChecklistItem.self, CalendarSettings.self,
        ])
    }

}
