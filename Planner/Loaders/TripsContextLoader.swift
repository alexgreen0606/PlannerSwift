//
//  TripsContextLoader.swift
//  Planner
//
//  Created by Alex Green on 11/10/26.
//

import SwiftData
import SwiftUI

struct TripsContextLoaderView<Content: View>: View {
    private let todaystamp: String
    private let content: (TripsContext) -> Content

    init(
        todaystamp: String,
        @ViewBuilder content: @escaping (TripsContext) -> Content
    ) {
        self.todaystamp = todaystamp
        self.content = content

        _sortedTrips = Query(
            filter: Trip.trips(onOrBefore: todaystamp),
            sort: \.firstDatestamp
        )
    }

    @Query private var sortedTrips: [Trip]

    private var sortedTripsByYear: [String: [Trip]] {
        Dictionary(grouping: sortedTrips) {
            $0.firstDatestamp.year
        }
    }

    private var sortedTripYears: [String] {
        sortedTripsByYear.keys.sorted(by: <)
    }

    // MARK: - Body

    var body: some View {
        content(
            TripsContext(
                sortedTrips: sortedTrips,
                sortedTripsByYear: sortedTripsByYear,
                sortedTripYears: sortedTripYears
            )
        )
    }
}
