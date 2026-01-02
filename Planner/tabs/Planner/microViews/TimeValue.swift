//
//  TimeValue.swift
//  Planner
//
//  Created by Alex Green on 12/3/25.
//

import SwiftUI

struct TimeValue: View {
    let date: Date
    let datestamp: String
    let disabled: Bool
    let color: Color
    let openEventSheet: (() -> Void)?

    @State private var isVisible = false

    private var timeInfo:
        (timeValue: String, indicator: String, detail: String?)
    {
        date.timeValues(for: datestamp)
    }

    var body: some View {
        let timeVal = HStack(alignment: .top, spacing: 1) {
            // Time Value (12:30)
            Text(timeInfo.timeValue)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(
                    disabled
                        ? Color(uiColor: .tertiaryLabel) : color
                )

            // Indicator (PM / AM)
            Text(timeInfo.indicator)
                .font(.system(size: 7, weight: .medium))
                .foregroundStyle(
                    disabled ? Color(uiColor: .tertiaryLabel) : Color.secondary
                )
        }
        .overlay(alignment: .topLeading) {
            if let detail = timeInfo.detail {
                // Multi-Day Detail (START / END)
                Text(detail)
                    .font(.system(size: 7, weight: .medium))
                    .foregroundStyle(
                        disabled
                            ? Color(uiColor: .tertiaryLabel) : Color.secondary
                    )
                    .offset(y: 16)
            }
        }
        .opacity(!isVisible ? 0 : 1)
        .animation(.easeIn(duration: 0.25), value: isVisible)
        .onAppear { isVisible = true }

        if openEventSheet == nil {
            timeVal
        } else {
            timeVal
                .contentShape(Rectangle())
                .onTapGesture(perform: openEventSheet!)
        }
    }
}
