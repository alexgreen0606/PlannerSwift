//
//  TripChip.swift
//  Planner
//
//  Created by Alex Green on 3/30/26.
//

import SwiftUI

// Clean

struct TripChipView: View {
    let trip: Trip
    let datestamp: String
    let settings: PlannerSettings

    private let chipHeight: CGFloat = 48
    private let progressBarWidth: CGFloat = 100

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue
    
    @State private var showTripSheet = false
    
    @Namespace private var namespace

    private var day: CGFloat {
        guard
            let index = trip.sortedPlanners.firstIndex(where: {
                $0.datestamp == datestamp
            })
        else {
            return 0.0
        }
        return Double(index) + 1.0
    }

    private var tripProgress: Double {
        guard trip.sortedPlanners.count > 0 else { return 0 }
        return day / Double(trip.sortedPlanners.count)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(trip.title)
                    .font(
                        .system(size: 16, weight: .bold, design: .rounded)
                    )
                    .foregroundStyle(
                        Color.label
                    )

                if let location = trip.location {
                    AdornedValueView(
                        location.name,
                        iconConfig: IconConfig(
                            name: "mappin.and.ellipse",
                            primaryColor: accentColor.color
                        ),
                        scale: 0.7
                    )
                }
            }
            .padding(.horizontal)

            Spacer()

            VStack(alignment: .trailing) {
                progressBar

                Text("Day \(Int(day)) of \(trip.sortedPlanners.count)")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
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
            in: .rect(
                cornerRadius: chipHeight / 2
            )
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
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.secondary.opacity(0.15))
                .frame(width: progressBarWidth)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            accentColor.color,
                            accentColor.color.opacity(0.7),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: progressBarWidth * tripProgress)
                .animation(.easeInOut(duration: 0.3), value: tripProgress)
        }
        .frame(height: 8)
    }
    
}
