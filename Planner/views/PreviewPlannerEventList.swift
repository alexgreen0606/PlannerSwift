//
//  PreviewEventList.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import SwiftUI

struct PreviewPlannerEventListView: View {
    let datestamp: String
    let events: [PlannerEvent]
    let remainingLabel: String?

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
                            .foregroundStyle(Color(uiColor: .label))

                        Spacer()

                        event.timeValueView(
                            for: datestamp,
                            openSheet: nil,
                            accentColor: accentColor.swiftUIColor
                        )
                    }

                    dashedDivider
                }

                if let remainingLabel {
                    Text(remainingLabel)
                        .font(
                            .system(size: 12, weight: .heavy, design: .rounded)
                        )
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
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
