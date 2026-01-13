//
//  PlannerDateInfo.swift
//  Planner
//
//  Created by Alex Green on 1/1/26.
//

import SwiftUI

struct PlannerDateInfoView: View {
    let datestamp: String

    private var date: Date? {
        datestamp.date
    }

    var body: some View {
        HStack {
            PlannerIcon(datestamp: datestamp, scale: 1.4)
            VStack(alignment: .leading) {
                Text(date?.weekday ?? datestamp)
                    .font(.headline)
                    .fontWeight(.bold)

                Text(datestamp.date?.countdown ?? "")
                    .font(.footnote)
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
