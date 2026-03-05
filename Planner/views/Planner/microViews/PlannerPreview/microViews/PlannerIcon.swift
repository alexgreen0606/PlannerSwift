//
//  PlannerIcon.swift
//  Planner
//
//  Created by Alex Green on 12/21/25.
//

import SwiftUI

struct PlannerIcon: View {
    let datestamp: String
    let scale: CGFloat

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @EnvironmentObject private var todaystampManager: TodaystampWatcher

    private var iconColor: Color {
        datestamp == todaystampManager.todaystamp
            ? accentColor.value : Color.secondary
    }

    var body: some View {
        ZStack(alignment: .top) {
            Image(systemName: datestamp.calendarSymbolName)
                .fixedSize()
                .foregroundStyle(Color.label, iconColor)
                .font(.system(size: 28 * scale))

            Text(datestamp.shortMonth)
                .font(.system(size: 6 * scale))
                .fontWeight(.heavy)
                .foregroundStyle(Color.calendarIconMonth)
                .offset(y: 1.5 * scale)
        }
    }
}
