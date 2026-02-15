//
//  TimeValue.swift
//  Planner
//
//  Created by Alex Green on 12/3/25.
//

import SwiftDate
import SwiftUI

struct TimeValue: View {
    let day: DateInRegion
    let disabled: Bool
    let color: Color
    let openEventSheet: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 1) {
            // Time Value (12:30)
            Text(day.timeValues.timeValue)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(
                    disabled
                        ? Color(uiColor: .tertiaryLabel) : color
                )

            // Indicator (PM / AM)
            Text(day.timeValues.indicator)
                .font(.system(size: 7, weight: .medium))
                .foregroundStyle(
                    disabled ? Color(uiColor: .tertiaryLabel) : Color.secondary
                )
        }
        .overlay(alignment: .topLeading) {
            if let detail = day.timeValues.detail {
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
        .contentShape(Rectangle())
        .onTapGesture(perform: openEventSheet)
    }
}
