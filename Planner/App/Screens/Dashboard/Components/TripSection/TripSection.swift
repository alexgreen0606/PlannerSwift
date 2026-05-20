//
//  TripSection.swift
//  Planner
//
//  Created by Alex Green on 5/18/26.
//

import SwiftData
import SwiftUI

struct TripSectionView: View {
    @Binding private var tripSheetContext: TripSheetContext?
    @Binding private var expandedTripIds: Set<PersistentIdentifier>
    private let scrollProxy: ScrollViewProxy
    private let settings: PlannerSettings
    private let namespace: Namespace.ID

    init(
        tripSheetContext: Binding<TripSheetContext?>,
        expandedTripIds: Binding<Set<PersistentIdentifier>>,
        todaystamp: String,
        scrollProxy: ScrollViewProxy,
        settings: PlannerSettings,
        namespace: Namespace.ID
    ) {
        self._tripSheetContext = tripSheetContext
        self._expandedTripIds = expandedTripIds
        self.scrollProxy = scrollProxy
        self.settings = settings
        self.namespace = namespace

        _sortedUpcomingTrips = Query(
            filter: #Predicate<Trip> {
                $0.lastDatestamp >= todaystamp
            },
            sort: \.firstDatestamp
        )
    }

    @Query private var sortedUpcomingTrips: [Trip]

    private var tripsByYear: [String: [Trip]] {
        Dictionary(grouping: sortedUpcomingTrips) {
            $0.firstDatestamp.year
        }
    }

    private var sortedTripYears: [String] {
        tripsByYear.keys.sorted(by: <)
    }

    // MARK: - Body

    var body: some View {
        if sortedUpcomingTrips.isEmpty {
            Section("Trips") {
                EmptyLabelView("No upcoming trips")
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
                        YearSectionHeaderView(year)
                    }
                }
                .padding([.horizontal, .bottom])
            }
            .listRowInsets(EdgeInsets())
            .discreetListItem()
        }
    }
}
