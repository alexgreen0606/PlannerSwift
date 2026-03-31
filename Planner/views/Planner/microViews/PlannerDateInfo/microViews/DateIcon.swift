//
//  DateIcon.swift
//  Planner
//
//  Created by Alex Green on 12/21/25.
//

import SwiftDate
import SwiftUI

// Clean

struct DateIconView: View {
    private let day: DateInRegion
    private let customSize: CGFloat?
    private let customMonthSize: CGFloat?
    private let customMonthOffset: CGFloat?

    init(
        day: DateInRegion,
        size: CGFloat? = nil,
        monthSize: CGFloat? = nil,
        monthOffset: CGFloat? = nil
    ) {
        self.day = day
        self.customSize = size
        self.customMonthSize = monthSize
        self.customMonthOffset = monthOffset
    }

    private let defaultSize: CGFloat = 40
    private let defaultMonthSize: CGFloat = 9
    private let defaultMonthOffset: CGFloat = 1.5

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @EnvironmentObject private var todaystampManager: TodaystampWatcher

    private var iconColor: Color {
        day.datestamp == todaystampManager.todaystamp
            ? accentColor.color : .secondary
    }

    private var size: CGFloat {
        customSize ?? defaultSize
    }

    private var monthSize: CGFloat {
        customMonthSize ?? defaultMonthSize
    }

    private var monthOffset: CGFloat {
        customMonthOffset ?? defaultMonthOffset
    }

    var body: some View {
        ZStack(alignment: .top) {
            Image(systemName: day.datestamp.calendarSymbolName)
                .fixedSize()
                .font(.system(size: size))
                .foregroundStyle(Color.label, iconColor)

            Text(day.shortMonth)
                .font(.system(size: monthSize))
                .fontWeight(.black)
                .foregroundStyle(Color.calendarIconMonth)
                .offset(y: monthOffset)
        }
    }
}
