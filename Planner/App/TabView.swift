//
//  TabView.swift
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

struct RootTabView: View {
    init() {
        // Date picker 5 minute intervals.
        UIDatePicker.appearance().minuteInterval = 5

        // Navigation titles rounded fonts.
        if var descriptor =
            UIFontDescriptor
                .preferredFontDescriptor(withTextStyle: .largeTitle)
                .withDesign(.rounded)
        {
            descriptor = descriptor.addingAttributes([
                .traits: [
                    UIFontDescriptor.TraitKey.weight: UIFont.Weight.heavy,
                ],
            ])

            UINavigationBar.appearance().largeTitleTextAttributes = [
                .font: UIFont(
                    descriptor: descriptor,
                    size: descriptor.pointSize
                ),
            ]
        }

        // Navigation subtitles rounded fonts.
        if var descriptor =
            UIFontDescriptor
                .preferredFontDescriptor(withTextStyle: .headline)
                .withDesign(.rounded)
        {
            descriptor = descriptor.addingAttributes([
                .traits: [
                    UIFontDescriptor.TraitKey.weight: UIFont.Weight.heavy,
                ],
            ])

            UINavigationBar.appearance().titleTextAttributes = [
                .font: UIFont(
                    descriptor: descriptor,
                    size: descriptor.pointSize
                ),
            ]
        }
    }

    private let contactsStore = CNContactStore()

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @AppStorage("lastCleansedDatestamp") var lastCleansedDatestamp: String = ""

    @AppStorage("keepPastEventsDuration") private var keepPastEventsDuration:
        KeepPastEventsDuration =
        .oneMonth

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var systemColorScheme
    @EnvironmentObject private var todaystampService: TodaystampService
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore
    @EnvironmentObject private var plannerSyncStore: PlannerSyncService

    @Query private var plannerSettingsList: [PlannerSettings]
    @Query private var checklistItems: [ChecklistItem]
    @Query private var planners: [Planner]

    @Namespace private var namespace

    @StateObject private var plannerSearchStore = PlannerSearchStore()

    private var settings: PlannerSettings? {
        plannerSettingsList.first
    }

    var body: some View {
        ZStack {
            if let settings {
                // MARK: Standard App Navigation

                TabView {
                    Tab(
                        "",
                        systemImage: todaystampService.todaystamp
                            .calendarSymbolName
                    ) {
                        DashboardRootView(
                            settings: settings,
                            namespace: namespace
                        )
                    }

                    Tab("", systemImage: "checklist") {
                        ChecklistsRootView()
                    }

                    Tab("", systemImage: "gear") {
                        SettingsRootView(settings: settings)
                    }

                    Tab(role: .search) {
                        PlannerContextLoaderView(
                            datestamp: todaystampService.todaystamp,
                            settings: settings
                        ) {
                            context in
                            PlannerSearchRootView(
                                todayDay: context.plannerDay,
                                settings: settings,
                                namespace: namespace
                            )
                            .environmentObject(plannerSearchStore)
                        }
                    }
                }
                .tabBarMinimizeBehavior(.onScrollDown)
                .accentColor(accentColor.color)
                .opacity(plannerCoverStore.isPresentingDefault ? 0 : 1)

                // MARK: Default App Landing. Today Planner Day.

                PlannerLoaderView(
                    datestamp: plannerCoverStore.todaystampAtInit,
                    settings: settings
                ) { plannerContext, eventContext in
                    PlannerRootView(
                        planner: plannerContext.planner,
                        plannerDay: plannerContext.plannerDay,
                        plannerLocation: plannerContext.plannerLocation,
                        eventContext: eventContext,
                        settings: settings
                    )
                }
                .opacity(plannerCoverStore.isPresentingDefault ? 1 : 0)
            }
        }
        .task {
            initializeAppData()
            initializePlannerSearchResults()
        }

        // MARK: Planner Day Cover

        .fullScreenCover(item: $plannerCoverStore.context) { context in
            if let settings {
                PlannerLoaderView(
                    datestamp: context.datestamp,
                    settings: settings
                ) { plannerContext, eventContext in
                    PlannerRootView(
                        planner: plannerContext.planner,
                        plannerDay: plannerContext.plannerDay,
                        plannerLocation: plannerContext.plannerLocation,
                        eventContext: eventContext,
                        settings: settings
                    )
                }
                .id(context.datestamp)
                .interactiveDismissDisabled(true)
                .navigationTransition(
                    .zoom(
                        sourceID: context.id,
                        in: namespace
                    )
                )
            }
        }

        // Refresh external data when the app focuses.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                calendarStore.refreshCalendarsAndAccess()
                syncAppIconWithSettings(
                    accentColor: accentColor,
                    systemColorScheme: systemColorScheme
                )
                plannerSyncStore.rebuildCalendarData()
            }
        }

        // Refresh weather data when the device's location changes.
        .onChange(
            of: locationService.deviceClLocation?.coordinate.key
        ) {
            _,
            _ in
            weatherStore.beginFreshReload()
        }
    }

    // MARK: - Functions

    private func initializePlannerSearchResults() {
        if let settings = plannerSettingsList.first {
            let todayPlanner = modelContext.getPlanner(
                for: todaystampService.todaystamp
            )

            guard
                let todayStartOfDay = todayPlanner.datestamp.startOfDay(
                    in: todayPlanner.region(settings: settings)
                )
            else {
                return
            }

            plannerSearchStore.search(
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
                    "ERROR TabView.initializeAppData: \(error)"
                )
            }
        }
    }

    /// Runs the first time the app opens each day.
    private func cleanseStorage() {
        guard lastCleansedDatestamp != todaystampService.todaystamp else {
            return
        }

        lastCleansedDatestamp = todaystampService.todaystamp

        if keepPastEventsDuration != .forever {
            modelContext.deleteStaleData(
                cutoffDate: keepPastEventsDuration.cutoffDate
            )
        }

        modelContext.safeSave("TabView.cleanseStorage")
    }
}
