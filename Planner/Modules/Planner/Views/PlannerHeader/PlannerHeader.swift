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
    private let datestamp: String
    private let customTextScale: Double?
    private let customTitle: String?
    private let customSubtitle: String?
    private let customIconFormat: DateFormat?
    private let customIconSize: CGFloat?
    private let customIconDetailOffset: CGFloat?
    private let customIconDetailSize: CGFloat?

    init(
        datestamp: String,
        customTextScale: Double? = nil,
        title: String? = nil,
        subtitle: String? = nil,
        iconFormat: DateFormat? = nil,
        iconSize: CGFloat? = nil,
        iconDetailSize: CGFloat? = nil,
        iconDetailOffset: CGFloat? = nil
    ) {
        self.datestamp = datestamp
        self.customTextScale = customTextScale
        customTitle = title
        customSubtitle = subtitle
        customIconFormat = iconFormat
        customIconSize = iconSize
        customIconDetailSize = iconDetailSize
        customIconDetailOffset = iconDetailOffset
    }

    @EnvironmentObject private var TodaystampService: TodaystampService

    private var todaystamp: String {
        TodaystampService.todaystamp
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
                todaystamp: todaystamp
            )
    }

    var subtitle: String {
        customSubtitle
            ?? datestamp.countdown(todaystamp: todaystamp)
    }

    var iconFormat: DateFormat {
        if let customIconFormat {
            return customIconFormat
        }

        if datestamp.isNext7Days(todaystamp: todaystamp)
            || datestamp.isWithinADay(todaystamp: todaystamp)
        {
            return .conciseMonth
        }

        return .conciseWeekday
    }

    var textScale: Double {
        customTextScale ?? 1
    }

    var body: some View {
        HStack {
            PlannerIconView(
                datestamp: datestamp,
                format: iconFormat,
                size: customIconSize,
                detailSize: customIconDetailSize,
                detailOffset: customIconDetailOffset
            )

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(
                        .system(
                            size: 18 * textScale,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(Color.label)

                Text(subtitle)
                    .font(.system(size: 11 * textScale, weight: .regular))
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}
