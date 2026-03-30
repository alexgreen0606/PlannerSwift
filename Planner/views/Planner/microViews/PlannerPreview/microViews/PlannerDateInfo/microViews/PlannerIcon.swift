//
//  PlannerIcon.swift
//  Planner
//
//  Created by Alex Green on 12/21/25.
//

import SwiftUI

// Clean

struct PlannerIconView: View {
    private let datestamp: String
    private let size: CGFloat
    private let monthOffset: CGFloat
    private let monthSize: CGFloat

    init(
        datestamp: String,
        size: CGFloat? = 28,
        monthOffset: CGFloat? = 1.5,
        monthSize: CGFloat? = 6
    ) {
        self.datestamp = datestamp
        self.size = size ?? 28
        self.monthOffset = monthOffset ?? 1.5
        self.monthSize = monthSize ?? 6
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @EnvironmentObject private var todaystampManager: TodaystampWatcher

    private var iconColor: Color {
        datestamp == todaystampManager.todaystamp
            ? accentColor.color : .secondary
    }

    var body: some View {
        ZStack(alignment: .top) {
            Image(systemName: datestamp.calendarSymbolName)
                .fixedSize()
                .foregroundStyle(Color.label, iconColor)
                .font(.system(size: size))

            Text(datestamp.shortMonth)
                .font(.system(size: monthSize))
                .fontWeight(.black)
                .foregroundStyle(Color.calendarIconMonth)
                .offset(y: monthOffset)
        }
    }
}
