//
//  Time.swift
//  Planner
//
//  Created by Alex Green on 12/3/25.
//

import SwiftDate
import SwiftUI

struct Time: View {
    private let timeInRegion: DateInRegion
    private let scale: Double

    init(
        timeInRegion: DateInRegion,
        color: Color? = nil,
        scale: Double = 1
    ) {
        self.timeInRegion = timeInRegion
        self.scale = scale

        customColor = color
    }

    private let customColor: Color?

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    /// Example: (12:37, PM)
    var details: (timeValue: String, indicator: String) {
        (
            timeValue: timeInRegion.toFormat("h:mm"),
            indicator: timeInRegion.toFormat("a")
        )
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 1 * scale) {
            Text(details.timeValue)
                .font(
                    .system(size: 14 * scale, weight: .black, design: .rounded)
                )
                .foregroundStyle(
                    customColor ?? accentColor.swiftUiColor
                )

            Text(details.indicator)
                .font(.system(size: 8 * scale))
                .foregroundStyle(
                    Color.secondary
                )
        }
    }
}
