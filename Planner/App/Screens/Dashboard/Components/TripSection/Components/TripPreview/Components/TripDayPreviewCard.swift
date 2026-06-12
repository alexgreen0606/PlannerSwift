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

    // MARK: - Body

    var body: some View {
        PlannerContextLoaderView(datestamp: datestamp, settings: settings) {
            context in
            PlannerPreviewCardView(
                planner: context.planner,
                sortedPlannerEvents: context.eventContext.sortedPlannerEvents,
                sortedEventChips: context.eventContext.sortedEventChips,
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
}
