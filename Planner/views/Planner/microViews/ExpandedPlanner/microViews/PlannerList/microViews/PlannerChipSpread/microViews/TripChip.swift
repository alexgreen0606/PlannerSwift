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

    private let chipHeight: CGFloat = 40

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    @State private var showTripSheet = false

    private var day: CGFloat {
        trip.day(of: planner.datestamp)
    }

    var body: some View {
        HStack {
            Group {
                Text(trip.title)
                    .font(
                        .system(size: 16, weight: .bold, design: .rounded)
                    )
                    .foregroundStyle(
                        Color.label
                    )

                Spacer()

                VStack(alignment: .trailing) {
                    progressBar

                    Text("Day \(Int(day)) of \(trip.sortedPlanners.count)")
                        .font(
                            .system(size: 9, weight: .heavy, design: .rounded)
                        )
                }
            }
            .padding(.horizontal)

        }
        .frame(maxWidth: .infinity)
        .frame(height: chipHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            showTripSheet = true
        }
        .glassEffect(
            .regular.interactive(true),
            in: .capsule
        )
        .matchedTransitionSource(
            id: IdConstants.TRIP_CHIP,
            in: namespace
        )

        // Trip Sheet
        .sheet(isPresented: $showTripSheet) {
            TripFormView(
                sourceTrip: trip,
                settings: settings
            )
            .navigationTransition(
                .zoom(
                    sourceID: IdConstants.TRIP_CHIP,
                    in: namespace
                )
            )
        }
    }

    // MARK: - View Builders

    private var progressBar: some View {
        trip.progressBar(day: day, accentColor: accentColor)
    }

}
