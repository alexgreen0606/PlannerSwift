//
//  PlannerDateInfo.swift
//  Planner
//
//  Created by Alex Green on 1/1/26.
//

import SwiftDate
import SwiftUI

// Clean

struct PlannerDateInfoView: View {
    let plannerStartOfDay: DateInRegion
    let isThisWeek: Bool

    private var title: String {
        return isThisWeek
            ? plannerStartOfDay.weekday : plannerStartOfDay.countdown
    }

    private var subtitle: String {
        isThisWeek ? plannerStartOfDay.countdown : plannerStartOfDay.weekday
    }

    var body: some View {
        PlannerIconView(datestamp: plannerStartOfDay.datestamp, scale: 1.4)
        VStack(alignment: .leading) {
            Text(title)
                .fontWeight(.bold)
                .fontDesign(.rounded)

            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
