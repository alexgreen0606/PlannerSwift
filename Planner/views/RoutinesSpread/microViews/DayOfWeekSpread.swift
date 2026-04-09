//
//  WeekdaySpread.swift
//  Planner
//
//  Created by Alex Green on 4/7/26.
//

import SwiftData
import SwiftDate
import SwiftUI

// Clean

struct WeekdaySpreadView: View {
    let selected: Set<Weekday>
    let scale: Double
    let spacing: CGFloat?

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(
                Weekday.allCases,
                id: \.self
            ) { weekday in
                Text(weekday.initial)
                    .foregroundStyle(
                        selected.contains(weekday)
                            ? accentColor.color : .tertiary
                    )
                    .font(
                        .system(
                            size: 16 * scale,
                            weight: .black,
                            design: .rounded
                        )
                    )
            }
        }
    }
}
