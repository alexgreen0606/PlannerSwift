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

    @EnvironmentObject private var todayService: TodayService

    var body: some View {
        PlannerPreviewCardView(
            variant: .planner,
            datestamp: datestamp,
            header: PlannerHeaderView(datestamp: datestamp),
            width: todayService.todaystamp == datestamp
                ? PlannerPreviewCardLayout.TODAY_WIDTH
                : PlannerPreviewCardLayout.DEFAULT_WIDTH,
            transitionId: datestamp,
            settings: settings,
            namespace: namespace
        )
    }
}
