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
    let customTitle: String?

    private var title: String {
        customTitle ?? plannerDay.previewTitle(type: type)
    }

    private var subtitle: String {
        plannerDay.previewSubtitle(type: type)
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
