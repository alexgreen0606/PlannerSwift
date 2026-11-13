//
//  TripRoot.swift
//  Planner
//
//  Created by Alex Green on 11/10/26.
//

import SwiftData
import SwiftDate
import SwiftUI

struct TripRootView: View {
    let settings: Settings
    let namespace: Namespace.ID

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @AppStorage("lastRefresh") private var lastRefresh: Double = 0

    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore
    @EnvironmentObject private var plannerService: PlannerService

    @State private var showNewRoutineEventSheet = false

    @State private var tripSheetContext: TripSheetContext? = nil

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                List {
                    UpcomingTripsView(
                        tripSheetContext: $tripSheetContext,
                        scrollProxy: scrollProxy,
                        settings: settings,
                        namespace: namespace
                    )
                }
                .listStyle(.plain)
                .refreshable {
                    calendarService.loadCalendars()
                    locationService.loadDeviceLocation()
                    plannerService.refresh()
                }
                .background(Color.appBackground)
                .safeAreaPadding(.bottom, 32)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Text("Trips")
                            .font(
                                .system(
                                    size: 28,
                                    weight: .bold,
                                    design: .rounded
                                )
                            )
                            .frame(width: 200, alignment: .leading)
                    }
                    .sharedBackgroundVisibility(.hidden)

                    createTripButton
                }

                // MARK: Scroll to expanded trips.

                .onChange(of: plannerService.expandedTripIds) {
                    oldIds,
                    newIds in
                    scrollProxy.scrollToNewItem(
                        oldItems: oldIds,
                        newItems: newIds,
                        getId: { $0 }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }

        // MARK: Trip Form

        .sheet(item: $tripSheetContext) { context in
            let form = TripFormView(
                sourceTrip: context.trip,
                settings: settings
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
    }

    // MARK: - Toolbars

    private var createTripButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Create Trip", systemImage: "plus") {
                tripSheetContext = TripSheetContext()
            }
        }
    }

    // MARK: - Function

    private func scrollToExpandedTrip(
        id: PersistentIdentifier,
        scrollProxy: ScrollViewProxy
    ) {
        DispatchQueue.main.async {
            withAnimation {
                scrollProxy.scrollTo(
                    tripRenderId(tripId: id, isExpanded: true),
                    anchor: .top
                )
            }
        }
    }
}
