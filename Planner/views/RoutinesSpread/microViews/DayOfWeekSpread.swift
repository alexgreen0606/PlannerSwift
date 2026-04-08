//
//  DayOfWeekSpread.swift
//  Planner
//
//  Created by Alex Green on 4/7/26.
//

import SwiftData
import SwiftDate
import SwiftUI

// Clean

struct DayOfWeekSpreadView: View {
    let selected: Set<DayOfWeek>
    let scale: Double
    let spacing: CGFloat?

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(
                DayOfWeek.allCases,
                id: \.self
            ) { dayOfWeek in
                Text(dayOfWeek.initial)
                    .foregroundStyle(
                        selected.contains(dayOfWeek)
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
