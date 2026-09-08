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
    let settings: Settings
    let namespace: Namespace.ID

    private let TRIP_CHIP_ID = "TRIP_CHIP"

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @EnvironmentObject private var plannerEngine: ListEngine<PlannerEvent>

    @State private var showTripSheet = false

    private var dayOfTrip: CGFloat {
        trip.day(of: planner.datestamp)
    }

    // MARK: - Body

    var body: some View {
        let chip = Group {
            HStack(spacing: 0) {
                Text(trip.title)
                    .lineLimit(2)
                    .font(
                        .system(size: 16, weight: .semibold, design: .rounded)
                    )
                    .foregroundStyle(plannerEngine.selectModeDisabledColor ?? Color.label)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing) {
                    ProgressBar(
                        trip: trip,
                        day: dayOfTrip,
                        color: plannerEngine.selectModeDisabledColor
                    )

                    Text(
                        "Day \(Int(dayOfTrip)) of \(trip.sortedPlanners.count)"
                    )
                    .font(
                        .system(size: 9, weight: .heavy, design: .rounded)
                    )
                    .foregroundStyle(plannerEngine.selectModeDisabledColor ?? Color.label)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity)
        .glassEffect(
            .regular.interactive(!plannerEngine.isSelectMode),
            in: .capsule
        )
        .matchedTransitionSource(
            id: TRIP_CHIP_ID,
            in: namespace
        )
        .contentShape(Rectangle())

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

        if !plannerEngine.isSelectMode {
            chip
                .onTapGesture {
                    showTripSheet = true
                }
        } else {
            chip
        }
    }
}
