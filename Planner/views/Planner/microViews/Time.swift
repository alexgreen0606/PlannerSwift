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
    let color: Color?
    let scale: Double
    let openEventSheet: (() -> Void)?

    init(
        timeInRegion: DateInRegion,
        color: Color? = nil,
        scale: Double = 1,
        openEventSheet: (() -> Void)? = nil
    ) {
        self.timeInRegion = timeInRegion
        self.color = color
        self.scale = scale
        self.openEventSheet = openEventSheet
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    var body: some View {
        let val = HStack(alignment: .top, spacing: 1 * scale) {

            // Time Value (12:30)
            Text(timeInRegion.timeValue.timeValue)
                .font(
                    .system(size: 14 * scale, weight: .black, design: .rounded)
                )
                .foregroundStyle(
                    color ?? accentColor.color
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
