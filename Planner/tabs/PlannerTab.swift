//
//  PlannerTab.swift
//  Planner
//
//  Created by Alex Green on 2/3/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

// Clean

struct PlannerTabView: View {
    let settings: PlannerSettings
    let namespace: Namespace.ID

    @AppStorage("keepPastPlansDuration") private var keepPastPlansDuration:
        KeepPastPlansDuration =
            KeepPastPlansDuration.oneMonth

    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager
    @EnvironmentObject private var plannerCoverManager: PlannerCoverManager

    @StateObject private var notificationManager = NotificationManager()
    @State private var showNewEventSheet = false
    @State private var showCalendarPicker = false
    @State private var selectedCalendarDate: Date = Date()
    @State private var thisWeekDatestamps: [String] = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("This week")
                        .sectionLabel()

                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(thisWeekDatestamps, id: \.self) {
                                datestamp in
                                PlannerBuilderView(
                                    datestamp: datestamp,
                                    settings: settings,
                                    previewType: .planner,
                                    namespace: namespace
                                )
                            }
                        }
                        .padding(.horizontal)
                        .animateAsynchronousAction(from: thisWeekDatestamps)
                    }
                    .scrollIndicators(.hidden)
                    .background(Color.clear)
                }
                .listRowInsets(EdgeInsets())
                .discreetListItem()
            }
            .listStyle(.plain)
            .background(Color.appBackground)
            .navigationTitle("Planner")
            .toolbar {
                datePickerToolbarPopover
                newEventToolbarButton
            }
            .refreshable {
                weatherStore.beginFreshReload()
                calendarStore.attemptFreshLoad(
                    hiddenCalendarIds: settings.hiddenCalendarIds
                )
                deviceLocationManager.loadDeviceLocation()
            }

            // New Event Form
            .sheet(isPresented: $showNewEventSheet) {
                EventFormView(
                    plannerEvent: nil,
                    calendarEvent: nil,
                    settings: settings
                )
                .navigationTransition(
                    .zoom(
                        sourceID: IdConstants.ADD_BUTTON,
                        in: namespace
                    )
                )
                .environmentObject(notificationManager)
            }
        }
        .overlay {
            NotificationsView()
                .environmentObject(notificationManager)
        }

        // Build the week's datestamps at midnight.
        .externalData(
            key: todaystampWatcher.todaystamp,
            ready: true,
            load: buildThisWeekDatestamps
        )
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var datePickerToolbarPopover: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Calendar", systemImage: "calendar") {
                showCalendarPicker = true
            }
            .popover(isPresented: $showCalendarPicker) {
                VStack {
                    DatePicker(
                        "Open a planner",
                        selection: $selectedCalendarDate,
                        in: keepPastPlansDuration
                            .cutoffDate...todaystampWatcher
                            .maxCalendarDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)

                    // Open planner when a new date is selected from the picker.
                    .onChange(of: selectedCalendarDate) { _, _ in
                        handlePlannerDateSelect()
                    }

                }
                .frame(width: 340, height: 320)
                .padding()
                .presentationCompactAdaptation(.popover)
            }
            .matchedTransitionSource(
                id: IdConstants.CALENDAR_BUTTON,
                in: namespace
            )
        }
    }

    private var newEventToolbarButton: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("New Event", systemImage: "plus") {
                showNewEventSheet = true
            }
            .matchedTransitionSource(
                id: IdConstants.ADD_BUTTON,
                in: namespace
            )
        }
    }

    // MARK: - Helper Functions

    private func buildThisWeekDatestamps() {
        thisWeekDatestamps = (0..<7).map {
            DateInRegion(Date(), region: .local)
                .dateByAdding($0, .day)
                .toFormat("yyyy-MM-dd")
        }.sorted()
    }

    private func handlePlannerDateSelect() {
        showCalendarPicker = false

        let localDate = DateInRegion(
            selectedCalendarDate,
            region: .local
        )

        DispatchQueue.main.async {
            plannerCoverManager.context = PlannerCoverContext(
                datestamp: localDate.datestamp,
                source: IdConstants.CALENDAR_BUTTON
            )
        }
    }

}
