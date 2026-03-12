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

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue
    
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        if !events.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(events, id: \.stableId) { event in
                    HStack(alignment: .top, spacing: 12) {
                        Text(event.title)
                            .font(.system(size: ListLayout.FONT_SIZE * 0.8))

                        Spacer()

                        event.timeValueView(
                            in: plannerRegion,
                            accentColor: accentColor,
                            scale: 0.8,
                            openSheet: nil
                        )
                    }

                    dashedDivider
                }
            }
        }
    }

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
