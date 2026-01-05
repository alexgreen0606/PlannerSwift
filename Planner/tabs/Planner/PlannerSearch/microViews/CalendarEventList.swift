//
//  CalendarEventList.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import SwiftUI

struct CalendarEventListView: View {
    let datestamp: String
    let events: [EKEvent]

    @Environment(\.displayScale) private var displayScale

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(events, id: \.self) { event in
                HStack(alignment: .top, spacing: 12) {
                    Text(event.title)
                        .font(.system(size: 15))
                        .foregroundStyle(Color(uiColor: .label))

                    Spacer()

                    event.timeValueView(
                        for: datestamp,
                                openEventSheet: nil,
                        animation: nil
                    )
                }

                if event.eventIdentifier
                    != events.last!.eventIdentifier
                {
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
                        Color(uiColor: .tertiaryLabel),
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            dash: [2, 6]
                        )
                    )
            )
    }

}
