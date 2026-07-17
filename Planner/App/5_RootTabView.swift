//
//  RootTabView.swift
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
    private let settings: Settings

    init(settings: Settings) {
        self.settings = settings

        // Date picker -> 5 minute intervals.
        UIDatePicker.appearance().minuteInterval = 5

        // Navigation titles -> rounded fonts.
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

            UINavigationBar.appearance().largeTitleTextAttributes = [
                .font: UIFont(
                    descriptor: descriptor,
                    size: descriptor.pointSize
                )
            ]
        }

        // Navigation subtitles -> rounded fonts.
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

            UINavigationBar.appearance().titleTextAttributes = [
                .font: UIFont(
                    descriptor: descriptor,
                    size: descriptor.pointSize
                )
            ]
        }
    }
    
    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var plannerService: PlannerService
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore

    @State private var selectedTab: TabId = .dashboard

    @Namespace private var namespace

    private var searchRefreshTrigger: String {
        "\(scenePhase)_\(selectedTab)_\(plannerCoverStore.context == nil)_\(todayService.todaystamp)"
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // MARK: Standard App Navigation

            TabView(selection: $selectedTab) {
                Tab(
                    "",
                    systemImage: todayService.todaystamp
                        .calendarSymbolName,
                    value: .dashboard
                ) {
                    DashboardRootView(
                        settings: settings,
                        namespace: namespace
                    )
                }

                Tab("", systemImage: "list.bullet", value: .checklists) {
                    ChecklistNavigationView(settings: settings)
                }

                Tab("", systemImage: "gear", value: .settings) {
                    SettingsRootView(settings: settings)
                }

                Tab(value: .search, role: .search) {
                    PlannerLoaderView(datestamp: todayService.todaystamp) {
                        planner in
                        SearchRootView(
                            todayPlanner: planner,
                            settings: settings,
                            namespace: namespace
                        )
                    }
                }
            }
            .tabBarMinimizeBehavior(.onScrollDown)
            .accentColor(accentColor.swiftUiColor)
            .opacity(plannerCoverStore.showTodayDefault ? 0 : 1)

            // MARK: Default App Landing. Today Planner.

            PlannerContextLoaderView(
                datestamp: plannerCoverStore.todaystampAtInit,
                settings: settings
            ) { context in
                PlannerRootView(
                    planner: context.planner,
                    sortedPlannerEvents: context.eventContext
                        .sortedPlannerEvents,
                    sortedEventChips: context.eventContext.sortedEventChips,
                    sortedBirthdayChips: context.eventContext
                        .sortedBirthdayChips,
                    settings: settings
                )
            }
            .opacity(plannerCoverStore.showTodayDefault ? 1 : 0)
        }

        // MARK: Search each time the search tab is active.
        .onChange(of: searchRefreshTrigger) { _, _ in
            if scenePhase == .active
                && selectedTab == .search
                && plannerCoverStore.context == nil
            {
                plannerService.search()
            }
        }

        // MARK: Planner Cover
        .fullScreenCover(item: $plannerCoverStore.context) { context in
            PlannerContextLoaderView(
                datestamp: context.datestamp,
                settings: settings
            ) { plannerContext in
                PlannerRootView(
                    planner: plannerContext.planner,
                    sortedPlannerEvents: plannerContext.eventContext
                        .sortedPlannerEvents,
                    sortedEventChips: plannerContext.eventContext
                        .sortedEventChips,
                    sortedBirthdayChips: plannerContext.eventContext
                        .sortedBirthdayChips,
                    settings: settings
                )
                .id(context.datestamp)
            }
            .navigationTransition(
                .zoom(
                    sourceID: context.id,
                    in: namespace
                )
            )
            .interactiveDismissDisabled(true)
        }

        // Note: Removed as onboarding now enforces a home location.
        // Sync weather data when the device's location changes.
        //        .onChange(
        //            of: locationService.deviceClLocation?.coordinate.id
        //        ) {
        //            _,
        //            _ in
        //            weatherCacheService.beginReload()
        //        }
    }
}
