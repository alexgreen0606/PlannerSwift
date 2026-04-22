//
//  ContentView.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import Contacts
import ContactsUI
import EventKit
import Fuse
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

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme
        .dark

    @AppStorage("keepCanceledEventsDuration") private
        var keepCanceledEventsDuration: KeepCanceledEventsDuration =
            KeepCanceledEventsDuration.startOfDay

    @AppStorage("lastCleansedDatestamp") var lastCleansedDatestamp: String = ""

    @AppStorage("keepPastEventsDuration") private var keepPastEventsDuration:
        KeepPastEventsDuration =
            KeepPastEventsDuration.oneMonth

    @Environment(\.scenePhase) private var appPhase
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var systemColorScheme
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var plannerCoverManager: PlannerCoverManager
    @EnvironmentObject private var plannerBuildManager: PlannerBuildManager

    @Query private var plannerSettingsList: [PlannerSettings]
    @Query private var checklistItems: [ChecklistItem]
    @Query private var planners: [Planner]

    @StateObject private var plannerSearchManager = PlannerSearchManager()
    @State private var enableMatchedAnimation = false

    @Namespace private var namespace

    private let contactsStore = CNContactStore()

    private var settings: PlannerSettings? {
        plannerSettingsList.first
    }

    var body: some View {
        ZStack {
            if let settings {

                // MARK: Standard App Navigation

                ToastRootView {
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

                        Tab("", systemImage: "gear") {
                            SettingsTabView(settings: settings)
                        }

                        Tab(role: .search) {
                            PlannerSearchTabView(
                                todaystamp: todaystampWatcher.todaystamp,
                                settings: settings,
                                namespace: namespace
                            )
                            .environmentObject(plannerSearchManager)
                        }
                    }
                    .tabBarMinimizeBehavior(.onScrollDown)
                    .opacity(plannerCoverManager.isPresentingDefault ? 0 : 1)
                }

                // MARK: Default App Landing. Today Planner.
                ToastRootView {
                    PlannerBuilderView(
                        datestamp: plannerCoverManager.todaystampAtInit,
                        settings: settings,
                        header: plannerCoverHeader(
                            plannerCoverManager.todaystampAtInit
                        )
                    )
                }
                .opacity(plannerCoverManager.isPresentingDefault ? 1 : 0)

            }
        }
        .task {
            initializeAppData()
            initializePlannerSearch()
        }

        // MARK: Expanded Planner Cover
        .fullScreenCover(item: $plannerCoverManager.context) { context in
            ToastRootView {
                if let settings {
                    PlannerBuilderView(
                        datestamp: context.datestamp,
                        settings: settings,
                        header: plannerCoverHeader(context.datestamp)
                    )
                }
            }
            .navigationTransition(
                .zoom(
                    sourceID: context.id,
                    in: namespace
                )
            )
            .interactiveDismissDisabled(true)
            .id(context.datestamp)
        }

        // Reload all calendar records when the app gains focus.
        .onChange(of: appPhase) { _, phase in
            if phase == .active {
                calendarStore.refreshCalendarsAndAccess()
                syncAppIconWithSettings(
                    accentColor: accentColor,
                    systemColorScheme: systemColorScheme
                )
                plannerBuildManager.rebuildCalendarData()
            }
        }

        // Re-load the weather when the device's location changes.
        .onChange(
            of: deviceLocationManager.deviceClLocation?.coordinate.key
        ) {
            _,
            _ in
            weatherStore.beginFreshReload()
        }
    }

    @ViewBuilder
    private func plannerCoverHeader(_ datestamp: String) -> some View {
        let isDateIcon =
            datestamp.isNext7Days(todaystamp: todaystampWatcher.todaystamp)
            || datestamp.isWithinADay(todaystamp: todaystampWatcher.todaystamp)
        PlannerHeaderView(
            datestamp: datestamp,
            customTextScale: 1.1,
            iconSize: 32,
            iconDetailSize: isDateIcon ? 9 : 11,
            iconDetailOffset: isDateIcon ? 3 : 18
        )
    }

    private func initializePlannerSearch() {
        if let settings = plannerSettingsList.first {

            let todayPlanner = modelContext.getPlanner(
                for: todaystampWatcher.todaystamp
            )
            guard
                let todayStartOfDay = todayPlanner.datestamp.startOfDay(
                    in: todayPlanner.region(settings: settings)
                )
            else {
                return
            }

            plannerSearchManager.search(
                with: PlannerSearchQuery(
                    text: "",
                    filteredCalendarIds: [],
                    filterPast: false,
                    todayStartOfDay: todayStartOfDay,
                    fuse: Fuse()
                ),
                modelContainer: modelContext.container,
                settings: settings,
                ekEventStore: calendarStore.ekEventStore
            )
        }
    }

    private func initializeAppData() {
        syncAppIconWithSettings(
            accentColor: accentColor,
            systemColorScheme: systemColorScheme
        )

        modelContext.ensurePlannerSettings(
            settings: plannerSettingsList
        )

        modelContext.ensureRootFolder(folders: checklistItems)

        calendarStore.refreshCalendarsAndAccess()

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
            modelContext.deleteStorageRecords(
                olderThan: keepPastEventsDuration.cutoffDate
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
