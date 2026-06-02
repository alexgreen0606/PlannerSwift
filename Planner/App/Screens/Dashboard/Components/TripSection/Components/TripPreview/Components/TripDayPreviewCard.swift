//
//  TripDayPreviewCard.swift
//  Planner
//
//  Created by Alex Green on 5/13/26.
//

import SwiftUI

struct TripDayPreviewCardView: View {
    let trip: Trip
    let datestamp: String
    let index: Int
    let settings: PlannerSettings
    let namespace: Namespace.ID

    var body: some View {
        PlannerPreviewCardView(
            variant: .trip,
            datestamp: datestamp,
            header: PlannerHeaderView(
                datestamp: datestamp,
                iconType: .date,
                title: "Day \(index + 1)",
                subtitle: datestamp.weekday
            ),
            transitionId: trip.transitionId(
                for: datestamp
            ),
            settings: settings,
            namespace: namespace
        )
    }
}
