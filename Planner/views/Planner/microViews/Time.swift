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

    var details: (timeValue: String, indicator: String) {  // Ex: (12:37, PM)
        // Convert to 12-hour format.
        let hour12 = timeInRegion.hour % 12 == 0 ? 12 : timeInRegion.hour % 12
        let timeValue = String(format: "%02d:%02d", hour12, timeInRegion.minute)

        // Drop off leading 0's.
        let trimmed = timeValue.drop(while: { $0 == "0" })

        // Determine AM or PM.
        let indicator = timeInRegion.hour < 12 ? "AM" : "PM"

        return (timeValue: String(trimmed), indicator: indicator)
    }

    var body: some View {
        let val = HStack(alignment: .top, spacing: 1 * scale) {

            // Time Value (12:30)
            Text(details.timeValue)
                .font(
                    .system(size: 14 * scale, weight: .black, design: .rounded)
                )
                .foregroundStyle(
                    color ?? accentColor.color
                )

            // Indicator (PM / AM)
            Text(details.indicator)
                .font(.system(size: 8 * scale, weight: .medium))
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
