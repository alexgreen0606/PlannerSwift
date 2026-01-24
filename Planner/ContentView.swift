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

struct ContentView: View {
    
    @AppStorage("keepCanceledPlansDuration") private
        var keepCanceledPlansDuration: KeepCanceledPlansDuration =
            KeepCanceledPlansDuration.startOfDay
    
    @AppStorage("lastCleansedDatestamp") var lastCleansedDatestamp: String = ""
    
    @AppStorage("keepPastPlansDuration") private var keepPastPlansDuration:
        KeepPastPlansDuration =
            KeepPastPlansDuration.oneMonth

    @Environment(\.modelContext) private var modelContext
    @Query private var calendarSettingsList: [CalendarSettings]
    @Query private var planners: [Planner]

    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    @EnvironmentObject var todaystampWatcher: TodaystampWatcher
    @EnvironmentObject var calendarStore: CalendarStore

    let contactsStore = CNContactStore()

    @State private var selectedTab: AppTab = .search
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
        TabView(selection: $selectedTab) {
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
//        .tabViewBottomAccessory {
//
//            // May want to add this in futue. For now it is too bulky and not useful enough to justify.
//            PlannerAccessoryView(
//                todaystamp: todaystampWatcher.todaystamp,
//                animation: todayPlannerCoverAnimation
//            ) {
//                isTodayPlannerOpen.toggle()
//            }
//
//        }
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

            do {
                try await contactsStore.requestAccess(for: .contacts)
            } catch {
                assertionFailure(
                    "Failed to request contacts access: \(error)"
                )
            }
        }
    }

    // Runs once at the start of every day to delete old data.
    private func cleanseStorage() {
        guard lastCleansedDatestamp != todaystampWatcher.todaystamp else {
            return
        }

        print("Sanitizing app storage...")
        lastCleansedDatestamp = todaystampWatcher.todaystamp

        if keepPastPlansDuration != .forever {
            
            // Delete sort indices for events that no longer exist in the calendar.
            if let calendarSettings {
                modelContext.deleteStaleCalendarEventPositions(
                    in: calendarSettings,
                    with: calendarStore.existingEventIds
                )
            }

            // Delete old planners.
            modelContext.deleteOldPlanners(
                from: planners,
                before: keepPastPlansDuration.cutoffDate
            )
        }
        
        if keepCanceledPlansDuration != .forever {
            
            let todaystamp = todaystampWatcher.todaystamp
            let descriptor = FetchDescriptor<Planner>(
                    predicate: #Predicate { planner in
                        planner.datestamp == todaystamp
                    }
                )

            do {
                if let todayPlanner = try modelContext.fetch(descriptor).first {
                    
                    // Delete canceled plans from today's planner.
                    modelContext.deleteCheckedPlans(from: todayPlanner)
                }
            } catch {
                assertionFailure(
                    "Failed to delete canceled plans: \(error)"
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
