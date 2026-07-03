//
//  DashboardRoot.swift
//  Planner
//
//  Created by Alex Green on 2/3/26.
//

import SwiftData
import SwiftDate
import SwiftUI

struct DashboardRootView: View {
    let settings: Settings
    let namespace: Namespace.ID

    private let CALENDAR_BUTTON_ID = "CALENDAR_BUTTON_ID"

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var weatherCacheService: WeatherCacheService
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore
    @EnvironmentObject private var plannerService: PlannerService

    @State private var showCalendarPicker = false
    @State private var tappedDates: Set<DateComponents> = []

    @State private var showNewEventSheet = false

    @State private var showNewRoutineEventSheet = false
    @State private var routineCoverContext: Weekday? = nil

    @State private var tripSheetContext: TripSheetContext? = nil
    @State private var expandedTripIds: Set<PersistentIdentifier> = []

    // MARK: - Body

    var body: some View {
        ToastRootView {
            NavigationStack {
                ScrollViewReader { scrollProxy in
                    List {
                        // MARK: THIS WEEK

                        ThisWeekSectionView(
                            settings: settings,
                            namespace: namespace
                        )

                        // MARK: ROUTINES

                        RoutineSectionView(
                            routineCoverContext: $routineCoverContext,
                            namespace: namespace
                        )

                        // MARK: Trips

                        TripSectionView(
                            tripSheetContext: $tripSheetContext,
                            expandedTripIds: $expandedTripIds,
                            scrollProxy: scrollProxy,
                            settings: settings,
                            namespace: namespace
                        )
                    }
                    .listStyle(.plain)
                    .refreshable {
                        weatherCacheService.beginReload()
                        calendarService.refreshCalendarsAndAccess()
                        locationService.loadDeviceLocation()
                        plannerService.refresh()
                    }
                    .background(Color.appBackground)
                    .safeAreaPadding(.bottom, 32)
                    .toolbar {
                        datePickerToolbarPopover
                        createMenu
                    }

                    // MARK: Scroll to expanded trips.

                    .onChange(of: expandedTripIds) { oldIds, newIds in
                        scrollProxy.scrollToNewItem(
                            oldItems: oldIds,
                            newItems: newIds,
                            getId: { $0 }
                        )
                    }
                }
            }

            // MARK: New Event Form

            .sheet(isPresented: $showNewEventSheet) {
                EventFormView(settings: settings)
            }

            // MARK: New Routine Event Form

            .sheet(isPresented: $showNewRoutineEventSheet) {
                RoutineEventFormView(
                    openRoutine: { weekday in
                        routineCoverContext = weekday
                    }
                )
            }

            // MARK: Trip Form

            .sheet(item: $tripSheetContext) { context in
                let form = TripFormView(
                    sourceTrip: context.trip,
                    settings: settings,
                    onSave: { trip in
                        _ = withAnimation {
                            expandedTripIds.insert(trip.id)
                        }
                    }
                )

                if let trip = context.trip {
                    form.navigationTransition(
                        .zoom(
                            sourceID: trip.transitionId,
                            in: namespace
                        )
                    )
                } else {
                    form
                }
            }

            // MARK: Routine Root

            .fullScreenCover(
                item: $routineCoverContext,
                onDismiss: plannerService.syncVisiblePlanners
            ) { weekday in
                RoutineContextLoaderView(weekday: weekday) { context in
                    RoutineRootView(
                        routineCoverContext: $routineCoverContext,
                        routine: context.routine,
                        sortedRoutineEventContexts: context
                            .sortedRoutineEventContexts,
                        weekday: weekday
                    )
                    .id(weekday)
                }
                .navigationTransition(
                    .zoom(
                        sourceID: weekday,
                        in: namespace
                    )
                )
                .interactiveDismissDisabled(true)
            }
        }
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var datePickerToolbarPopover: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Calendar", systemImage: "calendar") {
                showCalendarPicker = true
            }
            .matchedTransitionSource(
                id: CALENDAR_BUTTON_ID,
                in: namespace
            )
            .popover(isPresented: $showCalendarPicker) {
                Group {
                    MultiDatePicker(
                        "Open a planner",
                        selection: $tappedDates,
                        in: todayService.multiDatePickerBounds
                    )
                    .tint(accentColor.swiftUiColor)
                    .onChange(of: tappedDates) { _, selectedDates in
                        handlePlannerDateSelect(selectedDates: selectedDates)
                    }
                }
                .presentationCompactAdaptation(.popover)
                .frame(width: 340, height: 320)
                .padding()
            }
        }
    }

    private var createMenu: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Menu("Create Menu", systemImage: "plus") {
                Button(
                    "Create Event",
                    systemImage: "calendar.day.timeline.leading"
                ) {
                    showNewEventSheet = true
                }

                Button("Create Routine", systemImage: "repeat") {
                    showNewRoutineEventSheet = true
                }

                Button("Create Trip", systemImage: "suitcase") {
                    tripSheetContext = TripSheetContext()
                }
            }
        }
    }

    // MARK: - Function

    private func handlePlannerDateSelect(selectedDates: Set<DateComponents>) {
        guard let clickedDate = selectedDates.first,
            let datestamp = clickedDate.datestamp
        else { return }

        showCalendarPicker = false
        tappedDates.removeAll()

        plannerService.syncPlanner(
            datestamp: datestamp
        )

        DispatchQueue.main.async {
            plannerCoverStore.context = PlannerCoverContext(
                datestamp: datestamp,
                transitionId: CALENDAR_BUTTON_ID
            )
        }
    }

    private func scrollToExpandedTrip(
        id: PersistentIdentifier,
        scrollProxy: ScrollViewProxy
    ) {
        DispatchQueue.main.async {
            withAnimation {
                scrollProxy.scrollTo(
                    getTripRenderId(tripId: id, isExpanded: true),
                    anchor: .top
                )
            }
        }
    }
}
