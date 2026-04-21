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

struct TripSheetContext: Identifiable {
    var trip: Trip?

    var id: String {
        String(describing: trip?.id)
    }

    var transitionId: PersistentIdentifier? {
        trip?.id
    }

}

struct PlannerTabView: View {
    let settings: PlannerSettings
    let namespace: Namespace.ID

    init(settings: PlannerSettings, namespace: Namespace.ID) {
        self.settings = settings
        self.namespace = namespace

        self._thisWeekDatestamps = State(initialValue: getThisWeekDatestamps())
    }

    @AppStorage("keepPastEventsDuration") private var keepPastEventsDuration:
        KeepPastEventsDuration =
            KeepPastEventsDuration.oneMonth

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager
    @EnvironmentObject private var plannerCoverManager: PlannerCoverManager
    @EnvironmentObject private var plannerBuildManager: PlannerBuildManager

    @Query private var trips: [Trip]

    @StateObject private var notificationManager = NotificationManager()
    @State private var tappedDates: Set<DateComponents> = []
    @State private var showNewEventSheet = false
    @State private var showNewRoutineEventSheet = false
    @State private var showCalendarPicker = false
    @State private var thisWeekDatestamps: [String]
    @State private var tripSheetContext: TripSheetContext? = nil
    @State private var expandedTrips: Set<PersistentIdentifier> = []
    @State private var routineCoverContext: RoutineCoverContext? = nil

    private var sortedUpcomingTrips: [Trip] {
        trips.filter { trip in
            guard trip.firstDatestamp != nil,
                let lastDatestamp = trip.lastDatestamp
            else {
                return false
            }
            return lastDatestamp >= todaystampWatcher.todaystamp
        }.sorted { $0.firstDatestamp! < $1.firstDatestamp! }
    }

    private var tripsByYear: [String: [Trip]] {
        Dictionary(grouping: sortedUpcomingTrips) { trip in
            guard let firstDatestamp = trip.firstDatestamp else {
                return "Unknown"
            }
            return String(firstDatestamp.prefix(4))
        }
    }

    private var sortedTripYears: [String] {
        tripsByYear.keys.sorted(by: <)
    }

    private var dateBounds: Range<Date> {
        keepPastEventsDuration.cutoffDate..<todaystampWatcher.maxCalendarDate
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                List {

                    // MARK: THIS WEEK
                    Section {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(
                                    thisWeekDatestamps,
                                    id: \.self,
                                    content: plannerPreview
                                )
                            }
                            .frame(
                                height: PlannerLayout.PREVIEW_CARD_HEIGHT
                            )
                            .padding(.horizontal)
                            .animateAsynchronousAction(from: thisWeekDatestamps)
                        }
                        .scrollIndicators(.hidden)
                        .background(Color.clear)
                    } header: {
                        Text("This Week")
                            .padding()
                    }
                    .listSectionMargins(.top, 0)
                    .listRowInsets(EdgeInsets())
                    .discreetListItem()

                    // MARK: ROUTINES
                    Section("Routines") {
                        RoutinesSpreadView(
                            routineCoverContext: $routineCoverContext
                        )
                    }
                    .discreetListItem()

                    // MARK: TRIPS
                    ForEach(Array(sortedTripYears.enumerated()), id: \.element)
                    {
                        index,
                        year in
                        Section {
                            ForEach(tripsByYear[year]!, id: \.id) {
                                trip in
                                TripView(
                                    expandedTrips: $expandedTrips,
                                    trip: trip,
                                    namespace: namespace,
                                    settings: settings,
                                    scrollToTrip: {
                                        scrollToTrip(
                                            trip: trip,
                                            scrollProxy: scrollProxy
                                        )
                                    }
                                ) {
                                    tripSheetContext = TripSheetContext(
                                        trip: trip
                                    )
                                }
                            }
                        } header: {
                            ZStack {
                                if index == 0 {
                                    Text("Upcoming Trips")
                                } else {
                                    YearSectionHeaderView(year)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                        .listRowInsets(EdgeInsets())
                        .discreetListItem()
                    }

                    if sortedUpcomingTrips.isEmpty {
                        Section("Trips") {
                            EmptyLabelView("No upcoming trips")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .frame(height: 40, alignment: .center)
                        }
                        .discreetListItem()
                    }

                    // MARK: BOTTOM PADDING
                    Section {
                        Color.clear.frame(height: 16)
                    }
                    .discreetListItem()
                }
                .animation(.linear, value: expandedTrips)
                .listStyle(.plain)
                .background(Color.appBackground)
                .navigationTitle("Planner")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    datePickerToolbarPopover
                    createMenu
                }
                .refreshable {
                    weatherStore.beginFreshReload()
                    calendarStore.refreshCalendarsAndAccess()
                    deviceLocationManager.loadDeviceLocation()
                    plannerBuildManager.rebuildAllData()
                }

                // MARK: New Event Sheet
                .sheet(isPresented: $showNewEventSheet) {
                    EventFormView(
                        plannerEvent: nil,
                        calendarEvent: nil,
                        settings: settings
                    )
                }

                // MARK: New Routine Event Sheet
                .sheet(isPresented: $showNewRoutineEventSheet) {
                    RoutineEventFormView { weekday in
                        routineCoverContext = RoutineCoverContext(
                            weekday: weekday
                        )
                    }
                }

                // MARK: New Trip Sheet
                .sheet(item: $tripSheetContext) { context in
                    let form = TripFormView(
                        sourceTrip: context.trip,
                        settings: settings
                    ) {
                        trip in
                        expandedTrips.insert(trip.id)
                        scrollToTrip(trip: trip, scrollProxy: scrollProxy)
                    }

                    if let transitionId = context.transitionId {
                        form
                            .navigationTransition(
                                .zoom(
                                    sourceID: transitionId,
                                    in: namespace
                                )
                            )
                    } else {
                        form
                    }
                }
            }
            .overlay {
                if !notificationManager.notifications.isEmpty {
                    // Note: Must be rendered conditionally within this file.
                    // Changes to notifications are sometimes not recognized within the NotificationsView
                    // due to overlay restrictions.
                    NotificationsView()
                        .transition(
                            .move(edge: .leading).combined(with: .opacity)
                        )
                        .padding(.bottom)
                }
            }

            // Build the week's datestamps now and at midnight.
            .task(id: todaystampWatcher.todaystamp) {
                buildThisWeekDatestamps()
            }

            .environmentObject(notificationManager)
        }
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
                    MultiDatePicker(
                        "Open a planner",
                        selection: $tappedDates,
                        in: dateBounds
                    )
                    .tint(accentColor.color)
                    .onChange(of: tappedDates) { _, newValue in
                        guard let selected = newValue.first,
                            let year = selected.year,
                            let month = selected.month,
                            let day = selected.day
                        else { return }

                        handlePlannerDateSelect(
                            datestamp: String(
                                format: "%04d-%02d-%02d",
                                year,
                                month,
                                day
                            )
                        )

                        tappedDates.removeAll()
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

    // MARK: - View Builders

    private func plannerPreview(_ datestamp: String) -> some View {
        PlannerBuilderView(
            datestamp: datestamp,
            settings: settings,
            previewType: .planner,
            header: PlannerHeaderView(datestamp: datestamp),
            namespace: namespace
        )
    }

    // MARK: - Helper Functions

    private func buildThisWeekDatestamps() {
        thisWeekDatestamps = getThisWeekDatestamps()
    }

    private func handlePlannerDateSelect(datestamp: String) {
        showCalendarPicker = false

        DispatchQueue.main.async {
            plannerCoverManager.context = PlannerCoverContext(
                datestamp: datestamp,
                source: IdConstants.CALENDAR_BUTTON
            )
        }
    }

    private func scrollToTrip(trip: Trip, scrollProxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            let isExpanded = expandedTrips.contains(trip.id)
            let tripId = "\(trip.id)_\(String(isExpanded))"
            withAnimation {
                scrollProxy.scrollTo(tripId, anchor: .top)
            }
        }
    }

}
