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
    
    @AppStorage("keepPastPlansDuration") private var keepPastPlansDuration:
        KeepPastPlansDuration =
            KeepPastPlansDuration.oneMonth

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher
    @EnvironmentObject private var weatherStore: WeatherStore
    
    @Query private var calendarSettingsList: [CalendarSettings]

    @State private var plannerCoverContext: PlannerCoverContext?
    @Namespace private var sheetAnimation

    @State private var selectedCalendarDate: Date = Date()
    @State private var isNewEventSheetOpen = false
    @State private var isCalendarPickerOpen = false

    private var calendarSettings: CalendarSettings? {
        calendarSettingsList.first
    }

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
                            HStack(alignment: .top, spacing: 12) {
                                ForEach(thisWeekDatestamps, id: \.self) {
                                    datestamp in
                                    PlannerCardVerticalView(
                                        datestamp: datestamp
                                    ) {
                                        plannerCoverContext = PlannerCoverContext(
                                            datestamp: datestamp
                                        )
                                    }
                                    .matchedTransitionSource(
                                        id: datestamp,
                                        in: sheetAnimation
                                    )
                                }
                            }
                            .padding(.horizontal)
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
                .sheet(isPresented: $isNewEventSheetOpen) {
                    EventFormView(
                        plannerEvent: nil,
                        calendarEvent: nil
                    ) { _ in
                        // TODO: show indiactor of event creation
                    }
                    .navigationTransition(
                        .zoom(
                            sourceID: "ADD_EVENT",
                            in: sheetAnimation
                        )
                    )
                }
                
                // Open a planner.
                .fullScreenCover(item: $plannerCoverContext) { context in
                    PlannerView(datestamp: context.datestamp) {
                        plannerCoverContext = nil
                    }
                    .navigationTransition(
                        .zoom(
                            sourceID: context.customSource ?? context.datestamp,
                            in: sheetAnimation
                        )
                    )
                }
                
                // Reload the data from the page.
                .refreshable {
                    calendarStore.refresh(
                        hiddenCalendarIds: calendarSettings?.hiddenCalendarIds ?? []
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
                isCalendarPickerOpen = true
            }
            .popover(isPresented: $isCalendarPickerOpen) {
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
                        isCalendarPickerOpen = false

                        DispatchQueue.main.async {
                            plannerCoverContext = PlannerCoverContext(
                                datestamp: targetPlannerDate.datestamp,
                                customSource: "CALENDAR"
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
                in: sheetAnimation
            )
        }
    }

    @ToolbarContentBuilder
    private var topRightToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("New Event", systemImage: "plus") {
                isNewEventSheetOpen = true
            }
            .matchedTransitionSource(
                id: "ADD_EVENT",
                in: sheetAnimation
            )
        }
    }

}
