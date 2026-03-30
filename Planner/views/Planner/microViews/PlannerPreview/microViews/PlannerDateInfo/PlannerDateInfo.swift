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
    private let datestamp: String
    private let title: String
    private let subtitle: String
    private let iconSize: CGFloat?
    private let iconMonthOffset: CGFloat?
    private let iconMonthSize: CGFloat?

    init(
        datestamp: String,
        title: String,
        subtitle: String,
        iconSize: CGFloat? = nil,
        iconMonthOffset: CGFloat? = nil,
        iconMonthSize: CGFloat? = nil
    ) {
        self.datestamp = datestamp
        self.title = title
        self.subtitle = subtitle
        self.iconSize = iconSize
        self.iconMonthOffset = iconMonthOffset
        self.iconMonthSize = iconMonthSize
    }

    var body: some View {
        HStack {

            PlannerIconView(
                datestamp: datestamp,
                size: iconSize,
                monthOffset: iconMonthOffset,
                monthSize: iconMonthSize
            )

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

        }
    }
}
