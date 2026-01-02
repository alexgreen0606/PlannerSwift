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

    @EnvironmentObject var todaystampManager: TodaystampWatcher

    @AppStorage("themeColor") var themeColor: ThemeColorOption =
        ThemeColorOption.blue

    var iconColor: Color {
        datestamp == todaystampManager.todaystamp
        ? themeColor.swiftUIColor : Color(uiColor: .secondaryLabel)
    }

    var body: some View {
        Image(
            systemName: datestamp.calendarSymbolName
        )
        .foregroundStyle(Color(uiColor: .label), iconColor)
        .font(.system(size: 28 * scale))
        .overlay {
            Text(datestamp.shortMonth)
                .font(.system(size: 6 * scale))
                .fontWeight(.heavy)
                .padding(.bottom, 19 * scale)
                .foregroundStyle(Color.calendarIconMonth)
        }
    }
}
