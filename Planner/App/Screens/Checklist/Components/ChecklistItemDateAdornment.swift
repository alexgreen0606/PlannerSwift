//
//  ChecklistItemDateAdornment.swift
//  Planner
//
//  Created by Alex Green on 10/11/26.
//

import SwiftUI

struct ChecklistItemDateAdornment: View {
    let item: ChecklistItem

    @EnvironmentObject private var todaystampService: TodayService

    private var systemImageName: String {
        if let day = item.day {
            return "\(day).calendar"
        }

        return "note"
    }

    private var detail: String {
        guard let month = item.month else {
            return ""
        }

        return DateFormatter().shortMonthSymbols[month - 1].uppercased()
    }

    // Accented when the date matches today.
    var borderColor: Color {
        let todaystamp = todaystampService.todaystamp

        let isMonth =
            item.month == nil
            || item.month! == Int(todaystamp.monthDigit)
        let isDay =
            item.day == nil
            || item.day! == todaystamp.dayDigit
        let isYear =
            item.year == nil
            || String(item.year!) == todaystamp.year

        if isMonth && isDay && isYear {
            return item.parent?.color.swiftUIColor ?? Color.secondary
        }

        return Color.secondary
    }

    private var primaryIconColor: Color {
        item.day != nil ? Color.label : borderColor
    }

    private var detailColor: Color {
        Color.inverseLabel
    }

    // MARK: - Body

    var body: some View {
        if item.month != nil || item.day != nil || item.year != nil {
            VStack(spacing: 0) {
                DateIconView(
                    iconConfig: IconConfig(
                        name: systemImageName,
                        primaryColor: primaryIconColor,
                        secondaryColor: borderColor
                    ),
                    size: 32,
                    detail: detail,
                    detailSize: 8,
                    detailColor: detailColor,
                    detailOffset: 1.5
                )

                if let year = item.year {
                    Text(String(year))
                        .font(
                            .system(size: 8, weight: .heavy, design: .rounded)
                        )
                        .foregroundStyle(Color.secondary)
                }
            }
        }
    }
}
