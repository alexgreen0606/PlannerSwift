//
//  TripProgressBar.swift
//  Planner
//
//  Created by Alex Green on 7/3/26.
//

import SwiftUI

struct TripProgressBarView: View {
    private let trip: Trip
    private let day: CGFloat
    private let color: Color?

    init(trip: Trip, day: CGFloat, color: Color? = nil) {
        self.trip = trip
        self.day = day
        self.color = color
    }

    private let PROGRESS_BAR_WIDTH: CGFloat = 100

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    var progress: Double {
        guard trip.sortedPlanners.count > 0 else { return 0 }

        return day / Double(trip.sortedPlanners.count)
    }

    // MARK: - Body

    var body: some View {
        ProgressBarView(
            width: PROGRESS_BAR_WIDTH,
            progress: progress
        )
    }
}
