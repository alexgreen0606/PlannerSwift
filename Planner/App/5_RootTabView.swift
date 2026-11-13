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

    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var plannerService: PlannerService
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore

    @State private var selectedTab: TabId = .plannerList

    @Namespace private var namespace

    // MARK: - Body

    var body: some View {
        ZStack {
            // MARK: Standard App Navigation

            TabView(selection: $selectedTab) {
                Tab("", systemImage: "list.bullet", value: .checklists) {
                    ChecklistNavigationView(settings: settings)
                }

                Tab("", systemImage: "suitcase", value: .trips) {
                    TripRootView(settings: settings, namespace: namespace)
                }

                Tab(
                    "",
                    systemImage: todayService.todaystamp.calendarSymbolName,
                    value: .plannerList,
                    role: {
                        if #available(iOS 27, *) {
                            .prominent
                        } else {
                            nil
                        }
                    }()
                ) {
                    PlannerListRootView(
                        todayService: todayService,
                        settings: settings,
                        namespace: namespace
                    )
                }
            }
            .tabBarMinimizeBehavior(.onScrollDown)
            .accentColor(accentColor.swiftUiColor)
            .opacity(
                plannerCoverStore.showTodayDefault ? 0 : 1
            )

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
            .opacity(
                plannerCoverStore.showTodayDefault ? 1 : 0
            )
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
    }
}
