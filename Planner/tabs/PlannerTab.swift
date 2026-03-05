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

struct PlannerTabView: View {
    let settings: PlannerSettings
    let namespace: Namespace.ID

    @AppStorage("keepPastPlansDuration") private var keepPastPlansDuration:
        KeepPastPlansDuration =
            KeepPastPlansDuration.oneMonth

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager
    @EnvironmentObject private var plannerCoverManager: PlannerCoverManager

    @State private var selectedCalendarDate: Date = Date()
    @State private var showNewEventSheet = false
    @State private var showCalendarPicker = false

    private var thisWeekDatestamps: [String] {
        let region = Region.local
        let today = DateInRegion(Date(), region: region)

        return (0..<7).map {
            today
                .dateByAdding($0, .day)
                .toFormat("yyyy-MM-dd")
        }.sorted()
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
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
                    topLeftToolbar
                    topRightToolbar
                }

                // Create new event.
                .sheet(isPresented: $showNewEventSheet) {
                    EventFormView(
                        plannerEvent: nil,
                        calendarEvent: nil,
                        settings: settings
                    ) {
                        // TODO: show indiactor of event creation
                    }
                    .navigationTransition(
                        .zoom(
                            sourceID: "ADD_EVENT",
                            in: namespace
                        )
                    )
                }

                // Reload the data from the page.
                .refreshable {
                    weatherStore.beginFreshReload()
                    calendarStore.attemptFreshReload(
                        hiddenCalendarIds: settings.hiddenCalendarIds
                    )
                    deviceLocationManager.loadDeviceLocation()
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var topLeftToolbar: some ToolbarContent {
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
                    .onChange(of: selectedCalendarDate) {
                        _,
                        targetPlannerDate in
                        showCalendarPicker = false

                        let localDate = DateInRegion(
                            targetPlannerDate,
                            region: .local
                        )

                        DispatchQueue.main.async {
                            plannerCoverManager.context = PlannerCoverContext(
                                datestamp: localDate.datestamp,
                                source: "CALENDAR"
                            )
                        }
                    }
                }
                .frame(width: 340, height: 320)
                .padding()
                .presentationCompactAdaptation(.popover)
            }
            .matchedTransitionSource(
                id: "CALENDAR",
                in: namespace
            )
        }
    }

    @ToolbarContentBuilder
    private var topRightToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("New Event", systemImage: "plus") {
                showNewEventSheet = true
            }
            .matchedTransitionSource(
                id: "ADD_EVENT",
                in: namespace
            )
        }
    }

}
