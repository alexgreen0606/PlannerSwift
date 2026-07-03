//
//  TripSection.swift
//  Planner
//
//  Created by Alex Green on 5/18/26.
//

import SwiftData
import SwiftUI

struct TripSectionView: View {
    @Binding var tripSheetContext: TripSheetContext?
    @Binding var expandedTripIds: Set<PersistentIdentifier>
    let scrollProxy: ScrollViewProxy
    let settings: Settings
    let namespace: Namespace.ID

    @EnvironmentObject private var plannerService: PlannerService

    private var tripsByYear: [String: [Trip]] {
        Dictionary(grouping: plannerService.sortedUpcomingTrips) {
            $0.firstDatestamp.year
        }
    }

    private var sortedTripYears: [String] {
        tripsByYear.keys.sorted(by: <)
    }

    // MARK: - Body

    var body: some View {
        if plannerService.sortedUpcomingTrips.isEmpty {
            Section("Trips") {
                EmptyLabel("No upcoming trips")
                    .frame(
                        maxWidth: .infinity,
                        minHeight: 40
                    )
            }
            .discreetListItem()
        }

        ForEach(
            Array(sortedTripYears.enumerated()),
            id: \.element
        ) {
            index,
            year in
            Section {
                ForEach(tripsByYear[year]!, id: \.id) {
                    trip in
                    TripPreviewView(
                        expandedTripIds: $expandedTripIds,
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
                Group {
                    if index == 0 {
                        Text("Trips")
                    } else {
                        YearSectionHeader(year)
                    }
                }
                .padding([.horizontal, .bottom])
            }
            .listRowInsets(EdgeInsets())
            .discreetListItem()
        }
    }
}
