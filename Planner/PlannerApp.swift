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

    var uIColor: UIColor {
        switch self {
        case .red: return .systemRed
        case .orange: return .systemOrange
        case .yellow: return .systemYellow
        case .green: return .systemGreen
        case .blue: return .systemBlue
        case .indigo: return .systemIndigo
        case .purple: return .systemPurple
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
    
    let calendarStore = CalendarEventStore.shared
    @StateObject private var navigationManager = NavigationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .accentColor(themeColor.swiftUIColor)
                .environmentObject(TodaystampWatcher.shared)
                .environmentObject(calendarStore)
                .environmentObject(navigationManager)
                .onAppear {
                    calendarStore.requestAccessAndLoadIfNeeded()
                }
        }
        .modelContainer(for: [Planner.self, ChecklistItem.self, CalendarEventPositions.self])
    }

}
