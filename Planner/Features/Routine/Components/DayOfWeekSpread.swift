//
//  DayOfWeekSpread.swift
//  Planner
//
//  Created by Alex Green on 4/7/26.
//

import SwiftData
import SwiftDate
import SwiftUI

struct WeekdaySpreadView: View {
    let selected: Set<Weekday>
    let scale: Double
    let spacing: CGFloat?
    let customAccentColor: Color?

    init(
        selected: Set<Weekday>,
        scale: Double,
        spacing: CGFloat? = nil,
        customAccentColor: Color? = nil
    ) {
        self.selected = selected
        self.scale = scale
        self.spacing = spacing
        self.customAccentColor = customAccentColor
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(
                Weekday.allCases,
                id: \.self
            ) { weekday in
                Text(weekday.initial)
                    .foregroundStyle(
                        selected.contains(weekday)
                            ? customAccentColor ?? accentColor.color : .tertiary
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
