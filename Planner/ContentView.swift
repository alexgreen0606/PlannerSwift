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

    // Set the rounded design for all navigation titles.
    init() {
        // Large Title
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

        // Inline Title
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

    let contactsStore = CNContactStore()

    @AppStorage("keepCanceledPlansDuration") private
        var keepCanceledPlansDuration: KeepCanceledPlansDuration =
            KeepCanceledPlansDuration.startOfDay

    @AppStorage("lastCleansedDatestamp") var lastCleansedDatestamp: String = ""

    @AppStorage("keepPastPlansDuration") private var keepPastPlansDuration:
        KeepPastPlansDuration =
            KeepPastPlansDuration.oneMonth

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var plannerCoverManager: PlannerCoverManager

    @Query private var plannerSettingsList: [PlannerSettings]
    @Query private var foldersList: [ChecklistItem]
    @Query private var planners: [Planner]

    @State private var plannerSearchText: String = ""

    @Namespace private var namespace

    private var settings: PlannerSettings? {
        plannerSettingsList.first
    }

    // TODO: fix
    private var eventsForToday: [EKEvent] {
        []
        //        return calendarStore.allDayEventsByDatestamp[
        //            todaystampWatcher.todaystamp
        //        ] ?? []
    }

    var body: some View {
        ZStack {
            if let settings {
                TabView {
                    Tab("", systemImage: todaystampWatcher.todaystamp.calendarSymbolName) {
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
                        SettingsTabView()
                    }
                    
                    
                    Tab(role: .search) {
                        PlannerSearchTabView(
                            searchText: $plannerSearchText,
                            settings: settings,
                            namespace: namespace
                        )
                        .searchable(
                            text: $plannerSearchText,
                            prompt: "Search planner..."
                        )
                        .searchPresentationToolbarBehavior(.avoidHidingContent)
                    }
                }
                .tabBarMinimizeBehavior(.onScrollDown)
            }
        }

        // Planner Cover
        .fullScreenCover(item: $plannerCoverManager.context) { context in
            if let settings {
                PlannerBuilderView(datestamp: context.datestamp, settings: settings)
                    .navigationTransition(
                        .zoom(
                            sourceID: context.id,
                            in: namespace
                        )
                    )
            }
        }

        // Ensure all global storage objects exist.
        .task {
            modelContext.ensurePlannerSettings(
                settings: plannerSettingsList
            )

            modelContext.ensureRootFolder(folders: foldersList)

            calendarStore.attemptFreshReload(
                hiddenCalendarIds: settings!.hiddenCalendarIds
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

        // Re-load the weather when the device's location changes.
        .onChange(of: deviceLocationManager.deviceClLocation?.coordinate.key) {
            _,
            _ in
            print("Device location has changed. Refetching weather...")
            weatherStore.beginFreshReload()
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

            // TODO: fix this
            // Delete sort indices for events that no longer exist in the calendar.
            if let settings {
                modelContext.deleteStaleCalendarEventPositions(
                    in: settings,
                    with: []
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

                    // TODO: need to load in all the plans for this day

                    // Delete canceled plans from today's planner.
                    modelContext.deleteCheckedStorageEvents(from: [])
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
