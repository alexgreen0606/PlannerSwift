//
//  Time.swift
//  Planner
//
//  Created by Alex Green on 12/3/25.
//

import SwiftDate
import SwiftUI

// Clean

struct TimeView: View {
    let timeInRegion: DateInRegion
    let color: Color
    let scale: Double
    let openEventSheet: (() -> Void)?

    var body: some View {
        let val = HStack(alignment: .top, spacing: 1 * scale) {

            // Time Value (12:30)
            Text(timeInRegion.timeValue.timeValue)
                .font(
                    .system(size: 14 * scale, weight: .black, design: .rounded)
                )
                .foregroundStyle(
                    color
                )

            // Indicator (PM / AM)
            Text(timeInRegion.timeValue.indicator)
                .font(.system(size: 7 * scale, weight: .medium))
                .foregroundStyle(
                    Color.secondary
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
