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
    let plannerDay: DateInRegion
    let type: PlannerPreviewType
    let title: (DateInRegion) -> String
    let subtitle: (DateInRegion) -> String

    var body: some View {
        PlannerIconView(datestamp: plannerDay.datestamp, scale: 1.4)
        VStack(alignment: .leading) {
            Text(title(plannerDay))
                .fontWeight(.bold)
                .fontDesign(.rounded)

            Text(subtitle(plannerDay))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
