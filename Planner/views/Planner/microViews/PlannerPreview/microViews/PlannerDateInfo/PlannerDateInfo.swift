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

    private var title: String {
        plannerDay.previewTitle
    }

    private var subtitle: String {
        plannerDay.previewSubtitle
    }

    var body: some View {
        PlannerIconView(datestamp: plannerDay.datestamp, scale: 1.4)
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
