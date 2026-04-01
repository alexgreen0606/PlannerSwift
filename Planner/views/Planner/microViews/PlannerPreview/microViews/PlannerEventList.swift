//
//  PlannerEventList.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import SwiftDate
import SwiftUI

// Clean

struct PlannerEventListView: View {
    let plannerRegion: Region
    let events: [PlannerEvent]
    let isBottomOfCard: Bool

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.displayScale) private var displayScale

    var body: some View {
        if !events.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(events, id: \.stableId) { event in
                    HStack(alignment: .top) {
                        if event.isCompleted {
                            Image(systemName: "checkmark").imageScale(.small)
                        }

                        ValueView(event.title)

                        Spacer()

                        event.timeValueView(
                            in: plannerRegion,
                            accentColor: accentColor,
                            scale: 0.8,
                            openSheet: nil
                        )
                    }

                    if !isBottomOfCard
                        || event.stableId != events.last!.stableId
                    {
                        dashedDivider
                    }
                }
            }
        }
    }

    // MARK: - View Builders

    private var dashedDivider: some View {
        let lineWidth = 1 / displayScale

        return Rectangle()
            .fill(Color.clear)
            .frame(height: lineWidth)
            .overlay(
                Rectangle()
                    .stroke(
                        .tertiary,
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            dash: [2, 6]
                        )
                    )
            )
    }

}
