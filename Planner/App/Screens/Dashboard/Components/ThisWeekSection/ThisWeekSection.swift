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

    @EnvironmentObject private var plannerService: PlannerService

    // MARK: - Body

    var body: some View {
        Section {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(
                        plannerService.thisWeekDatestamps,
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
        .listRowInsets(EdgeInsets())
        .discreetListItem()
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
