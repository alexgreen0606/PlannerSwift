//
//  WeekdaySpread.swift
//  Planner
//
//  Created by Alex Green on 4/7/26.
//

import SwiftUI

struct WeekdaySpreadView: View {
    let selected: Set<Weekday>
    let spacing: CGFloat
    let scale: Double
    let customAccentColor: Color?

    init(
        selected: Set<Weekday>,
        spacing: CGFloat = 1,
        scale: Double = 1,
        accentColor: Color? = nil
    ) {
        self.selected = selected
        self.scale = scale
        self.spacing = spacing
        customAccentColor = accentColor
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    // MARK: - Body

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(
                Weekday.allCases,
                id: \.self
            ) { weekday in
                Text(weekday.initial)
                    .font(
                        .system(
                            size: 11 * scale,
                            weight: .black,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(
                        selected.contains(weekday)
                            ? customAccentColor ?? accentColor.swiftUiColor : .tertiary
                    )
            }
        }
    }
}
