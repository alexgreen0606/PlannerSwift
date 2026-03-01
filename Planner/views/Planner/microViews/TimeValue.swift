//
//  TimeValue.swift
//  Planner
//
//  Created by Alex Green on 12/3/25.
//

import SwiftDate
import SwiftUI

struct TimeValueView: View {
    let day: DateInRegion
    let disabled: Bool
    let color: Color
    let scale: Double
    let openEventSheet: (() -> Void)?

    var body: some View {
        let val = HStack(alignment: .top, spacing: 1 * scale) {
            // Time Value (12:30)
            Text(day.timeValues.timeValue)
                .font(.system(size: 14 * scale, weight: .black, design: .rounded))
                .foregroundStyle(
                    disabled
                        ? Color(uiColor: .tertiaryLabel) : color
                )

            // Indicator (PM / AM)
            Text(day.timeValues.indicator)
                .font(.system(size: 7 * scale, weight: .medium))
                .foregroundStyle(
                    disabled ? Color(uiColor: .tertiaryLabel) : Color.secondary
                )
        }
        
        if let openEventSheet {
            val
                .contentShape(Rectangle())
                .onTapGesture(perform: openEventSheet)
        } else {
            val
        }
    }
}
