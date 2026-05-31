//
//  PlannerEventList.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import SwiftDate
import SwiftUI

struct PlannerEventListView: View {
    let plannerRegion: Region
    let events: [PlannerEvent]
    let isBottomOfCard: Bool
    let settings: PlannerSettings

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.displayScale) private var displayScale

    // MARK: - Body

    var body: some View {
        if !events.isEmpty {
            ForEach(events, id: \.stableId) { event in
                HStack(alignment: .top) {
                    Group {
                        if event.isCompleted {
                            Image(systemName: "checkmark")
                        }

                        if let calendar = event.calendarEvent?.calendar {
                            Image(
                                systemName: calendar.systemImageName(
                                    settings: settings
                                )
                            )
                            .foregroundStyle(calendar.color)
                        } else if event.calendarItemExternalIdentifier != nil {
                            Image(systemName: "calendar")
                                .foregroundStyle(accentColor.color)
                        }
                    }
                    .imageScale(.small)
                    .frame(height: 17)

                    Value(event.title)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    event.timeAdornment(
                        in: plannerRegion,
                        accentColor: accentColor,
                        scale: 0.8
                    )
                    .frame(height: 17)
                }

                if !isBottomOfCard
                    || event.stableId != events.last!.stableId
                {
                    dashedDivider
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
