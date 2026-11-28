//
//  CalendarMonthTab.swift
//  Planner
//
//  Created by Alex Green on 11/18/26.
//

import SwiftDate
import SwiftUI

struct CalendarMonthTabView: View {
    let monthstamp: String
    let datestamps: [String?]
    let weekdayColumns: [GridItem]
    /// When false, only the empty grid is drawn and nothing is loaded.
    let isActive: Bool
    let settings: Settings
    let namespace: Namespace.ID

    var body: some View {
        VStack(spacing: 0) {
            // Note: Part of the page so it slides with the weekday row and grid.
            monthHeader

            WeekdayHeaderColumnsView(
                columns: weekdayColumns
            )

            GeometryReader { geo in
                let height = geo.size.height / 6

                if isActive {
                    CalendarMonthLoaderView(
                        datestamps: datestamps,
                        laneCount: CalendarWeekRowView.laneCount(
                            forRowHeight: height
                        ),
                        settings: settings
                    ) { layout in
                        monthGrid(layout: layout, height: height)
                    }
                } else {
                    monthGrid(layout: nil, height: height)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    // MARK: - View Builders

    /// Month and year. Smaller than the other pages' `PageTitle` to leave room for the grid.
    private var monthHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(monthstamp.month)
                .font(
                    .system(
                        size: 22,
                        weight: .bold,
                        design: .rounded
                    )
                )

            Text(monthstamp.year)
                .font(
                    .system(
                        size: 11,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private func monthGrid(layout: CalendarMonthLayout?, height: CGFloat)
        -> some View
    {
        VStack(spacing: 0) {
            ForEach(0..<(datestamps.count / 7), id: \.self) { week in
                CalendarWeekRowView(
                    datestamps: Array(datestamps[(week * 7)..<(week * 7 + 7)]),
                    layout: layout?.week(week),
                    height: height,
                    settings: settings,
                    namespace: namespace
                )
            }
        }
    }
}
