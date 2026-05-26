//
//  ThisWeekSection.swift
//  Planner
//
//  Created by Alex Green on 5/18/26.
//

import SwiftUI

struct ThisWeekSectionView: View {
    let settings: PlannerSettings
    let namespace: Namespace.ID

    @EnvironmentObject private var todaystampService: TodaystampService

    // MARK: - Body

    var body: some View {
        Section {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(
                        todaystampService.next7Datestamps,
                        id: \.self,
                        content: plannerPreview
                    )
                }
                .frame(
                    height: PlannerPreviewCardLayout.HEIGHT
                )
                .padding(.horizontal)
            }
            .background(Color.clear)
            .scrollIndicators(.hidden)
        } header: {
            Text("This Week")
                .padding([.horizontal, .bottom])
        }
        .listSectionMargins(.top, 0)
        .listRowInsets(EdgeInsets())
        .discreetListItem()
        .animateLazyAction(
            from: todaystampService.next7Datestamps
        )
    }

    // MARK: - View Builder

    private func plannerPreview(_ datestamp: String) -> some View {
        UpcomingDayPreviewCardView(
            datestamp: datestamp,
            settings: settings,
            namespace: namespace
        )
    }
}
