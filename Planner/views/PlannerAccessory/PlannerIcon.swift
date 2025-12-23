//
//  PlannerIcon.swift
//  Planner
//
//  Created by Alex Green on 12/21/25.
//

import SwiftUI

struct PlannerIcon: View {
    @EnvironmentObject var todaystampManager: TodaystampManager
    
    @AppStorage("themeColor") var themeColor: ThemeColorOption =
        ThemeColorOption.blue

    var body: some View {
        Image(
            systemName: todaystampManager.todaystamp.calendarSymbolName
        )
        .foregroundStyle(Color(uiColor: .label), themeColor.swiftUIColor)
        .font(.system(size: 28))
        .overlay {
            Text("DEC")
                .font(.system(size: 6))
                .fontWeight(.heavy)
                .padding(.bottom, 18)
                .foregroundStyle(Color.calendarIconMonth)
        }
    }
}
