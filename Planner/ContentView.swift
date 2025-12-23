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
    @EnvironmentObject var todaystampManager: TodaystampManager

    @State var navigationManager = NavigationManager.shared
    @EnvironmentObject var calendarEventStore: CalendarEventStore

    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    @AppStorage("lastCleanedDatestamp") var lastCleanedDatestamp: String = ""
    @AppStorage("themeColor") var themeColor: ThemeColorOption =
        ThemeColorOption.blue

    @State private var searchText: String = ""

    let plannerManager = ListManager()

    // Tracks the previously opened today datestamp. Must be local so midnight update does not
    // force the open planner to switch over.
    @State private var todayDatestamp: String = ""
    @State private var isTodayPlannerOpen: Bool = false

    @Namespace private var todayPlannerCoverNamespace

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

            Tab(value: .recurring) {
            } label: {
                Label("", systemImage: "repeat")
            }

            Tab(value: .search, role: .search) {
                NavigationStack {
                    PlannerSelectView()
                }
                .searchable(text: $searchText, prompt: "Search calendar events...")
            } label: {
                Label(
                    "",
                    systemImage: "calendar"
                )
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            PlannerAccessoryView(animation: todayPlannerCoverNamespace) {
                todayDatestamp = todaystampManager.todaystamp
                isTodayPlannerOpen.toggle()
            }
        }
        .fullScreenCover(isPresented: $isTodayPlannerOpen) {
            NavigationStack {
                PlannerView(
                    datestamp: todayDatestamp
                ) {
                    isTodayPlannerOpen.toggle()
                }
            }
            .environmentObject(plannerManager)
            .navigationTransition(
                .zoom(sourceID: "PLANNER_ACCESSORY", in: todayPlannerCoverNamespace)
            )
        }
    }
}

#Preview {
    ContentView()
}
