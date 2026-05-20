//
//  UpcomingDayPreviewCard.swift
//  Planner
//
//  Created by Alex Green on 5/13/26.
//

import SwiftUI

struct UpcomingDayPreviewCardView: View {
    let datestamp: String
    let settings: PlannerSettings
    let namespace: Namespace.ID

    @EnvironmentObject private var todaystampService: TodaystampService

    var body: some View {
        PlannerPreviewCardView(
            datestamp: datestamp,
            header: PlannerHeaderView(datestamp: datestamp),
            width: todaystampService.todaystamp == datestamp
                ? PlannerPreviewCardLayout.TODAY_WIDTH
                : PlannerPreviewCardLayout.DEFAULT_WIDTH,
            settings: settings,
            namespace: namespace,
            transitionId: datestamp
        )
    }
}
