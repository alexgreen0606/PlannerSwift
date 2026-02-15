//
//  PreviewEventList.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import SwiftUI
import SwiftDate

struct PreviewPlannerEventListView: View {
    let datestamp: String
    let events: [PlannerEvent]
    let hideLastDivider: Bool

    @Environment(\.displayScale) private var displayScale

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    var body: some View {
        if !events.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(events, id: \.id) { event in
                    HStack(alignment: .top, spacing: 12) {
                        Text(event.title)
                            .font(.system(size: 15))
                            .foregroundStyle(Color.label)

                        Spacer()

                        event.timeValueView(
                            // TODO: pass correct region
                            in: .local,
                            openSheet: nil,
                            accentColor: accentColor.swiftUIColor
                        )
                    }

                    if !hideLastDivider || event != events.last! {
                        dashedDivider
                    }
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
