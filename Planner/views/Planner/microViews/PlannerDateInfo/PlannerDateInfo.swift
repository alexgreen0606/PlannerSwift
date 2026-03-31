//
//  PlannerHeader.swift
//  Planner
//
//  Created by Alex Green on 1/1/26.
//

import SwiftDate
import SwiftUI

// Clean

struct PlannerHeaderView: View {
    private let day: DateInRegion

    private let customTitle: String?
    private let customSubtitle: String?
    private let customIconFormat: DateFormat?
    private let customIconSize: CGFloat?
    private let customIconDetailOffset: CGFloat?
    private let customIconDetailSize: CGFloat?

    init(
        day: DateInRegion,
        title: String? = nil,
        subtitle: String? = nil,
        iconFormat: DateFormat? = nil,
        iconSize: CGFloat? = nil,
        iconDetailSize: CGFloat? = nil,
        iconDetailOffset: CGFloat? = nil
    ) {
        self.day = day
        self.customTitle = title
        self.customSubtitle = subtitle
        self.customIconFormat = iconFormat
        self.customIconSize = iconSize
        self.customIconDetailSize = iconDetailSize
        self.customIconDetailOffset = iconDetailOffset
    }

    var title: String {
        customTitle ?? plannerTitle(day: day)
    }

    var subtitle: String {
        customSubtitle ?? plannerSubtitle(day: day)
    }

    var iconFormat: DateFormat {
        customIconFormat ?? plannerIconFormat(day: day)
    }

    var body: some View {
        HStack {

            if iconFormat == .shortMonth {
                DateIconView(
                    day: day,
                    size: customIconSize,
                    monthSize: customIconDetailSize,
                    monthOffset: customIconDetailOffset
                )
            } else {
                WeekdayIconView(
                    day: day,
                    size: customIconSize,
                )
            }

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
