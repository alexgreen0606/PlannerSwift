//
//  UpcomingTrips.swift
//  Planner
//
//  Created by Alex Green on 5/18/26.
//

import SwiftData
import SwiftUI

struct UpcomingTripsView: View {
    @Binding var tripSheetContext: TripSheetContext?
    let tripsContext: TripsContext
    let scrollProxy: ScrollViewProxy
    let settings: Settings
    let namespace: Namespace.ID

    @EnvironmentObject private var plannerService: PlannerService
    @EnvironmentObject private var todayService: TodayService

    // MARK: - Body

    var body: some View {
        ForEach(
            Array(tripsContext.sortedTripYears.enumerated()),
            id: \.element
        ) {
            index,
            year in
            Section {
                ForEach(tripsContext.sortedTripsByYear[year]!, id: \.id) {
                    trip in
                    TripPreviewView(
                        trip: trip,
                        settings: settings,
                        namespace: namespace,
                        openEditSheet: {
                            tripSheetContext = TripSheetContext(
                                trip: trip
                            )
                        }
                    )
                }
            } header: {
                if index != 0 {
                    YearSectionHeader(year)
                        .padding([.horizontal, .bottom])
                }
            }
            .listRowInsets(EdgeInsets())
            .discreetListItem()
        }
    }
}
