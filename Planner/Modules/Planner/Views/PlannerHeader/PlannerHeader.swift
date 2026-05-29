//
//  PlannerHeader.swift
//  Planner
//
//  Created by Alex Green on 1/1/26.
//

import SwiftDate
import SwiftUI

struct PlannerHeaderView: View {
    private let datestamp: String

    init(
        datestamp: String,
        iconType: PlannerIconType? = nil,
        iconSize: CGFloat? = nil,
        iconDetailSize: CGFloat? = nil,
        iconDetailOffset: CGFloat? = nil,
        title: String? = nil,
        subtitle: String? = nil,
    ) {
        self.datestamp = datestamp

        customIconType = iconType
        customIconSize = iconSize
        customIconDetailSize = iconDetailSize
        customIconDetailOffset = iconDetailOffset

        customTitle = title
        customSubtitle = subtitle
    }

    private let customIconType: PlannerIconType?
    private let customIconSize: CGFloat?
    private let customIconDetailSize: CGFloat?
    private let customIconDetailOffset: CGFloat?

    private let customTitle: String?
    private let customSubtitle: String?

    @EnvironmentObject private var todayService: TodayService

    var iconType: PlannerIconType {
        if let customIconType {
            return customIconType
        }

        if datestamp.isNext7Days(todaystamp: todayService.todaystamp) {
            return .date
        }

        return .weekday
    }

    var title: String {
        customTitle
            ?? datestamp.proximityFormat(
                using: [
                    ProximityRule(
                        proximity: .next7Days,
                        format: .weekday
                    ),
                    ProximityRule(
                        proximity: .fallback,
                        format: .dateLabel
                    ),
                ],
                todaystamp: todayService.todaystamp
            )
    }

    var subtitle: String {
        customSubtitle
            ?? datestamp.countdown(todaystamp: todayService.todaystamp)
    }

    // MARK: - Body

    var body: some View {
        HStack {
            PlannerIconView(
                type: iconType,
                datestamp: datestamp,
                size: customIconSize,
                detailSize: customIconDetailSize,
                detailOffset: customIconDetailOffset
            )

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .font(
                        .system(
                            size: 20,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(Color.label)

                Text(subtitle)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}
