//
//  TripChip.swift
//  Planner
//
//  Created by Alex Green on 3/30/26.
//

import SwiftUI

struct TripChipView: View {
    let trip: Trip
    let planner: Planner
    let settings: PlannerSettings
    let namespace: Namespace.ID

    private let TRIP_CHIP_ID = "TRIP_CHIP"

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @State private var showTripSheet = false

    private var dayOfTrip: CGFloat {
        trip.day(of: planner.datestamp)
    }

    // MARK: - Body

    var body: some View {
        Group {
            HStack(spacing: 0) {
                Text(trip.title)
                    .lineLimit(2)
                    .font(
                        .system(size: 16, weight: .bold, design: .rounded)
                    )
                    .foregroundStyle(Color.label)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing) {
                    progressBar

                    Text(
                        "Day \(Int(dayOfTrip)) of \(trip.sortedPlanners.count)"
                    )
                    .font(
                        .system(size: 9, weight: .heavy, design: .rounded)
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity)
        .glassEffect(
            .regular.interactive(true),
            in: .capsule
        )
        .matchedTransitionSource(
            id: TRIP_CHIP_ID,
            in: namespace
        )
        .contentShape(Rectangle())
        .onTapGesture {
            showTripSheet = true
        }

        // MARK: Trip Sheet
        .sheet(isPresented: $showTripSheet) {
            TripFormView(
                sourceTrip: trip,
                settings: settings
            )
            .navigationTransition(
                .zoom(
                    sourceID: TRIP_CHIP_ID,
                    in: namespace
                )
            )
        }
    }

    // MARK: - View Builders

    private var progressBar: some View {
        trip.progressBar(day: dayOfTrip, accentColor: accentColor)
    }
}
