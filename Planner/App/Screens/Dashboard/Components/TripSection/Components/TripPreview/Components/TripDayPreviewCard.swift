//
//  TripDayPreviewCard.swift
//  Planner
//
//  Created by Alex Green on 5/13/26.
//

import SwiftUI

struct TripDayPreviewCardView: View {
    let datestamp: String
    let index: Int
    let trip: Trip
    let settings: PlannerSettings
    let namespace: Namespace.ID

    var body: some View {
        PlannerPreviewCardView(
            datestamp: datestamp,
            header: PlannerHeaderView(
                datestamp: datestamp,
                title: "Day \(index + 1)",
                subtitle: datestamp.weekday,
                iconFormat: .conciseMonth
            ),
            settings: settings,
            namespace: namespace,
            transitionId: trip.transitionId(
                for: datestamp
            )
        )
    }
}
