//
//  ContentView.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import EventKit
import SwiftDate
import SwiftUI

struct ContentView: View {
    @AppStorage("lastCleanedDatestamp") var lastCleanedDatestamp: String = ""
    @AppStorage("themeColor") var themeColor: ThemeColorOption =
        ThemeColorOption.blue

    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    @EnvironmentObject var todaystampManager: TodaystampWatcher
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var calendarEventStore: CalendarEventStore

    @StateObject private var todayPlannerManager = ListManager()

    @State private var isTodayPlannerOpen: Bool = false
    @Namespace private var todayPlannerCoverAnimation

    @State private var searchText: String = ""

    private var eventsForToday: [EKEvent] {
        return calendarEventStore.allDayEventsByDatestamp[
            todaystampManager.todaystamp
        ] ?? []
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

            Tab(value: .search, role: .search) {
                NavigationStack {
                    PlannerSearchView()
                }
                .searchable(
                    text: $searchText,
                    prompt: "Search calendar events..."
                )
            } label: {
                Label(
                    "",
                    systemImage: "calendar"
                )
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            PlannerAccessoryView(
                todaystamp: todaystampManager.todaystamp,
                animation: todayPlannerCoverAnimation
            ) {
                isTodayPlannerOpen.toggle()
            }
        }
        .fullScreenCover(isPresented: $isTodayPlannerOpen) {
            NavigationStack {
                PlannerView(
                    datestamp: todaystampManager.todaystamp
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
    }
}

#Preview {
    ContentView()
}
