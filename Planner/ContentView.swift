//
//  ContentView.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

struct ContentView: View {
    @AppStorage("lastCleansedDatestamp") var lastCleansedDatestamp: String = ""
    @AppStorage("themeColor") var themeColor: ThemeColor =
        ThemeColor.blue

    @Environment(\.modelContext) private var modelContext
    @Query private var calendarSettingsList: [CalendarSettings]

    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    @EnvironmentObject var todaystampWatcher: TodaystampWatcher
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var calendarStore: CalendarStore

    @StateObject private var todayPlannerManager = ListManager()
    @State private var isTodayPlannerOpen: Bool = false
    @Namespace private var todayPlannerCoverAnimation

    private var eventsForToday: [EKEvent] {
        return calendarStore.allDayEventsByDatestamp[
            todaystampWatcher.todaystamp
        ] ?? []
    }

    private var calendarSettings: CalendarSettings? {
        calendarSettingsList.first
    }

    // Set the styles for all of the tab headers.
    init() {
        // Large Title
        if var descriptor = UIFontDescriptor.preferredFontDescriptor(
            withTextStyle: .largeTitle
        )
        .withDesign(.rounded) {
            // heavy weight
            descriptor = descriptor.addingAttributes([
                .traits: [
                    UIFontDescriptor.TraitKey.weight: UIFont.Weight.heavy
                ]
            ])

            // font size
            let customSize: CGFloat = 32
            let font = UIFont(descriptor: descriptor, size: customSize)
            UINavigationBar.appearance().largeTitleTextAttributes = [
                .font: font
            ]
        }

        // Inline Title
        if var descriptor = UIFontDescriptor.preferredFontDescriptor(
            withTextStyle: .headline
        )
        .withDesign(.rounded) {
            // heavy weight
            descriptor = descriptor.addingAttributes([
                .traits: [
                    UIFontDescriptor.TraitKey.weight: UIFont.Weight.heavy
                ]
            ])

            // font size
            let customSize: CGFloat = 26
            let font = UIFont(descriptor: descriptor, size: customSize)
            UINavigationBar.appearance().titleTextAttributes = [
                .font: font
            ]
        }
    }

    var body: some View {
        TabView(selection: $navigationManager.selectedTab) {
            Tab(value: .checklists) {
                ChecklistsTabView()
            } label: {
                Label(
                    "",
                    systemImage: "list.bullet"
                )
            }

            Tab(value: .routines) {
            } label: {
                Label("", systemImage: "repeat")
            }

            Tab(value: .settings) {
                SettingsView()
            } label: {
                Label("", systemImage: "gear")
            }

            Tab(value: .search, role: .search) {
                PlannerSearchView()
            } label: {
                Label(
                    "",
                    systemImage: "calendar"
                )
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {

            // TODO: this is re-rendered in each tab. Prevent this if possible.
            // Pending Apple fix.
            PlannerAccessoryView(
                todaystamp: todaystampWatcher.todaystamp,
                animation: todayPlannerCoverAnimation
            ) {
                isTodayPlannerOpen.toggle()
            }

        }
        .fullScreenCover(isPresented: $isTodayPlannerOpen) {
            NavigationStack {
                PlannerView(
                    datestamp: todaystampWatcher.todaystamp
                ) {
                    isTodayPlannerOpen.toggle()
                }
            }
            .environmentObject(todayPlannerManager)
            .navigationTransition(
                .zoom(
                    sourceID: "PLANNER_ACCESSORY",
                    in: todayPlannerCoverAnimation
                )
            )
        }
        .task {
            modelContext.ensureCalendarSettings(
                settings: calendarSettingsList
            )

            calendarStore.requestAccessAndLoadIfNeeded(
                hiddenCalendarIds: calendarSettings!.hiddenCalendarIds
            )

            cleanseStorage()
        }
    }

    // Runs once at the start of every day to cleanup old data.
    private func cleanseStorage() {
        guard lastCleansedDatestamp != todaystampWatcher.todaystamp else {
            return
        }

        lastCleansedDatestamp = todaystampWatcher.todaystamp
        print("Running app cleanup...")

        // Delete sort indices for events that no longer exist in the calendar.
        if let calendarSettings {
            modelContext.deleteStaleCalendarEventPositions(
                in: calendarSettings,
                with: calendarStore.existingEventIds
            )
        }

        // 1: Delete canceled plans. First: add setting "Delete canceled plans: Never/Start of day"
        // 2: Delete planners older than chosen delay. First: add setting "Delete planners after: 1 month/3 months/6 months/Never"
    }
}

#Preview {
    ContentView()
}
