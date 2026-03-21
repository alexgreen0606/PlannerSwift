//
//  ContentView.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import Contacts
import ContactsUI
import EventKit
import SwiftData
import SwiftDate
import SwiftUI

// Clean

struct ContentView: View {

    init() {

        // Set all date pickers to 5 minute intervals.
        UIDatePicker.appearance().minuteInterval = 5

        // Give large nav titles rounded font.
        if var descriptor =
            UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .largeTitle)
            .withDesign(.rounded)
        {

            descriptor = descriptor.addingAttributes([
                .traits: [
                    UIFontDescriptor.TraitKey.weight: UIFont.Weight.heavy
                ]
            ])

            let font = UIFont(
                descriptor: descriptor,
                size: descriptor.pointSize
            )
            UINavigationBar.appearance().largeTitleTextAttributes = [
                .font: font
            ]
        }

        // Give inline nav titles rounded font.
        if var descriptor =
            UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .headline)
            .withDesign(.rounded)
        {

            descriptor = descriptor.addingAttributes([
                .traits: [
                    UIFontDescriptor.TraitKey.weight: UIFont.Weight.heavy
                ]
            ])

            let font = UIFont(
                descriptor: descriptor,
                size: descriptor.pointSize
            )
            UINavigationBar.appearance().titleTextAttributes = [
                .font: font
            ]
        }
    }

    @AppStorage("keepCanceledEventsDuration") private
        var keepCanceledEventsDuration: KeepCanceledEventsDuration =
            KeepCanceledEventsDuration.startOfDay

    @AppStorage("lastCleansedDatestamp") var lastCleansedDatestamp: String = ""

    @AppStorage("keepPastEventsDuration") private var keepPastEventsDuration:
        KeepPastEventsDuration =
            KeepPastEventsDuration.oneMonth

    @Environment(\.scenePhase) private var appPhase
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var plannerCoverManager: PlannerCoverManager

    @Query private var plannerSettingsList: [PlannerSettings]
    @Query private var checklistItems: [ChecklistItem]
    @Query private var planners: [Planner]

    @State private var plannerSearchText: String = ""

    @Namespace private var namespace

    private let contactsStore = CNContactStore()

    private var settings: PlannerSettings? {
        plannerSettingsList.first
    }

    var body: some View {
        ZStack {
            if let settings {
                TabView {
                    Tab(
                        "",
                        systemImage: todaystampWatcher.todaystamp
                            .calendarSymbolName
                    ) {
                        PlannerTabView(
                            settings: settings,
                            namespace: namespace
                        )
                    }

                    Tab("", systemImage: "checklist") {
                        ChecklistsTabView()
                    }

                    Tab("", systemImage: "repeat") {
                        NavigationStack {
                            VStack {

                            }
                            .navigationTitle("Routines")
                        }
                    }

                    Tab("", systemImage: "gear") {
                        SettingsTabView(settings: settings)
                    }

                    Tab(role: .search) {
                        PlannerSearchTabView(
                            searchText: $plannerSearchText,
                            settings: settings,
                            namespace: namespace
                        )
                        .searchable(
                            text: $plannerSearchText,
                            prompt: "Search planner...",
                        )
                        .searchPresentationToolbarBehavior(.avoidHidingContent)
                    }
                }
                .tabBarMinimizeBehavior(.onScrollDown)
            }
        }
        .onAppear(perform: initializeAppData)

        // Expanded Planner Cover
        .fullScreenCover(item: $plannerCoverManager.context) { context in
            if let settings {
                PlannerBuilderView(
                    datestamp: context.datestamp,
                    settings: settings
                )
                .navigationTransition(
                    .zoom(
                        sourceID: context.id,
                        in: namespace
                    )
                )
            }
        }

        // Reload all calendar records when the app gains focus.
        .onChange(of: appPhase) { _, phase in
            if phase == .active, let settings {
                calendarStore.attemptFreshLoad(
                    hiddenCalendarIds: settings.hiddenCalendarIds
                )
            }
        }

        // Delete all calendar records when the calendar access is denied.
        .onChange(of: calendarStore.calendarAccessDenied == true) {
            _,
            accessDenied in
            if accessDenied {
                // TODO: delete all calendar planner events from storage
            }
        }

        // Re-load the weather when the device's location changes.
        .onChange(of: deviceLocationManager.deviceClLocation?.coordinate.key) {
            _,
            _ in
            weatherStore.beginFreshReload()
        }
    }

    private func initializeAppData() {
        modelContext.ensurePlannerSettings(
            settings: plannerSettingsList
        )

        modelContext.ensureRootFolder(folders: checklistItems)

        calendarStore.attemptFreshLoad(
            hiddenCalendarIds: settings!.hiddenCalendarIds
        )

        cleanseStorage()

        Task {
            do {
                try await contactsStore.requestAccess(for: .contacts)
            } catch {
                assertionFailure(
                    "ERROR ContentView.initializeAppData: \(error)"
                )
            }
        }
    }

    // Runs once at the start of every day to delete old data.
    private func cleanseStorage() {
        guard lastCleansedDatestamp != todaystampWatcher.todaystamp else {
            return
        }

        lastCleansedDatestamp = todaystampWatcher.todaystamp

        if keepPastEventsDuration != .forever {
            modelContext.deleteOldData(
                before: keepPastEventsDuration.cutoffDate
            )
        }

        if keepCanceledEventsDuration != .forever, let settings {
            modelContext.deleteCanceledPlans(
                for: todaystampWatcher.todaystamp,
                settings: settings
            )
        }
        
        modelContext.safeSave("ContentView.cleanseStorage")
    }

}
