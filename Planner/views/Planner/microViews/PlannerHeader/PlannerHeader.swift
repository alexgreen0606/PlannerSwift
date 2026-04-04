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
    private let customTitle: String?
    private let customSubtitle: String?
    private let customIconFormat: DateFormat?
    private let customIconSize: CGFloat?
    private let customIconDetailOffset: CGFloat?
    private let customIconDetailSize: CGFloat?

    init(
        datestamp: String,
        title: String? = nil,
        subtitle: String? = nil,
        iconFormat: DateFormat? = nil,
        iconSize: CGFloat? = nil,
        iconDetailSize: CGFloat? = nil,
        iconDetailOffset: CGFloat? = nil
    ) {
        self.datestamp = datestamp
        self.customTitle = title
        self.customSubtitle = subtitle
        self.customIconFormat = iconFormat
        self.customIconSize = iconSize
        self.customIconDetailSize = iconDetailSize
        self.customIconDetailOffset = iconDetailOffset
    }

    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher

    private var todaystamp: String {
        todaystampWatcher.todaystamp
    }

    var title: String {
        customTitle
            ?? plannerTitle(
                datestamp: datestamp,
                todaystamp: todaystamp
            )
    }

    var subtitle: String {
        customSubtitle
            ?? plannerSubtitle(
                datestamp: datestamp,
                todaystamp: todaystamp
            )
    }

    var iconFormat: DateFormat {
        customIconFormat
            ?? plannerIconFormat(datestamp: datestamp, todaystamp: todaystamp)
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
                    .font(.headline)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

        }
    }
}
