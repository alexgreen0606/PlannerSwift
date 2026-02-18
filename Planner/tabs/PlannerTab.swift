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
    let plannerSettings: PlannerSettings

    @AppStorage("keepPastPlansDuration") private var keepPastPlansDuration:
        KeepPastPlansDuration =
            KeepPastPlansDuration.oneMonth

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher
    @EnvironmentObject private var weatherStore: WeatherStore

    @State private var openDatestamp: PlannerDatestamp? = nil
    @State private var openPlanner: Planner? = nil
    @Namespace private var namespace

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
            ScrollViewReader { proxy in
                List {
                    Section {
                        Text("This week")
                            .sectionLabel()

                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(thisWeekDatestamps, id: \.self) {
                                    datestamp in
                                    PlannerPreviewBuilderView(
                                        datestamp: datestamp,
                                        type: .planner,
                                        plannerSettings: plannerSettings,
                                        openPlanner: $openPlanner
                                    )
                                    .matchedTransitionSource(
                                        id: datestamp,
                                        in: namespace
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
                        plannerSettings: plannerSettings
                    ) { _ in
                        // TODO: show indiactor of event creation
                    }
                    .navigationTransition(
                        .zoom(
                            sourceID: "ADD_EVENT",
                            in: namespace
                        )
                    )
                }

                // Open a planner (from a card)
                .fullScreenCover(item: $openPlanner) { planner in
                    PlannerView(
                        planner: planner,
                        plannerSettings: plannerSettings
                    ) {
                        openPlanner = nil
                    }
                    .navigationTransition(
                        .zoom(
                            sourceID: planner.datestamp,
                            in: namespace
                        )
                    )
                }

                // Open a Planner (from calendar)
                .fullScreenCover(item: $openDatestamp) { datestamp in
                    PlannerBuilderView(
                        datestamp: datestamp.id,
                        plannerSettings: plannerSettings,
                    ) {
                        openDatestamp = nil
                    }
                    .navigationTransition(
                        .zoom(
                            sourceID: "CALENDAR",
                            in: namespace
                        )
                    )
                }

                // Reload the data from the page.
                .refreshable {
                    calendarStore.loadFreshCache(
                        hiddenCalendarIds: plannerSettings.hiddenCalendarIds
                    )
                    Task {
                        await weatherStore.resetWeather()
                    }
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
                            openDatestamp = PlannerDatestamp(
                                id: localDate.datestamp
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
