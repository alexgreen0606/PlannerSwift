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

    @AppStorage("keepPastEventsDuration") private var keepPastEventsDuration:
        KeepPastEventsDuration =
            KeepPastEventsDuration.oneMonth

    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager
    @EnvironmentObject private var plannerCoverManager: PlannerCoverManager

    @Query private var trips: [Trip]

    @StateObject private var notificationManager = NotificationManager()
    @State private var tappedDates: Set<DateComponents> = []
    @State private var showNewEventSheet = false
    @State private var showCalendarPicker = false
    @State private var thisWeekDatestamps: [String] = []
    @State private var tripSheetContext: TripSheetContext? = nil
    @State private var expandedTrips: Set<PersistentIdentifier> = []

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
                    Section {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(thisWeekDatestamps, id: \.self) {
                                    datestamp in
                                    PlannerBuilderView(
                                        datestamp: datestamp,
                                        settings: settings,
                                        previewType: .planner,
                                        title: { day in
                                            day.proximityFormat(
                                                using: [
                                                    ProximityRule(
                                                        proximity: .withinADay,
                                                        format: .countdown
                                                    ),
                                                    ProximityRule(
                                                        proximity: .fallback,
                                                        format: .weekday
                                                    ),
                                                ]
                                            )
                                        },
                                        subtitle: { day in
                                            day.proximityFormat(
                                                using: [
                                                    ProximityRule(
                                                        proximity: .withinADay,
                                                        format: .weekday
                                                    ),
                                                    ProximityRule(
                                                        proximity: .fallback,
                                                        format: .countdown
                                                    ),
                                                ]
                                            )
                                        },
                                        namespace: namespace
                                    )
                                }
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
                    } footer: {
                        if !tripsByYear.isEmpty {
                            Color.clear.frame(height: 0)
                                .overlay {
                                    Text("Trips")
                                        .sectionLabel()
                                        .frame(
                                            maxWidth: .infinity,
                                            alignment: .leading
                                        )
                                        .padding(.top, 100)
                                }
                        }
                    }
                    .listSectionMargins(.bottom, 0)
                    .listRowInsets(EdgeInsets())
                    .discreetListItem()

                    if tripsByYear.isEmpty {
                        EmptyLabelView(text: "No Upcoming Trips")
                            .frame(maxWidth: .infinity)
                            .padding().discreetListItem()
                    }

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
                            YearSectionHeaderView(year)
                                .padding()
                        } footer: {
                            if index == sortedTripYears.count - 1 {
                                Color.clear.frame(height: 16)
                                    .discreetListItem()
                            }
                        }
                        .listSectionMargins(.top, 0)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
                .animation(.linear, value: expandedTrips)
                .listStyle(.plain)
                .background(Color.appBackground)
                .navigationTitle("Planner")
                .toolbar {
                    datePickerToolbarPopover
                    createMenu
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
                    .environmentObject(notificationManager)
                }

                // New Trip Form
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
                NotificationsView()
                    .padding(.bottom)
                    .environmentObject(notificationManager)
            }

            // Build the week's datestamps at midnight.
            .externalData(
                key: todaystampWatcher.todaystamp,
                ready: true,
                load: buildThisWeekDatestamps
            )
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

                Button("Create Trip", systemImage: "suitcase") {
                    tripSheetContext = TripSheetContext()
                }
            }
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
