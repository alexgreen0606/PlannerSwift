//
//  CalendarMonthTab.swift
//  Planner
//
//  Created by Alex Green on 11/18/26.
//

import SwiftDate
import SwiftUI

struct CalendarMonthTabView: View {
    let datestamps: [String?]
    let weekdayColumns: [GridItem]
    /// When false, only the empty grid is drawn and nothing is loaded.
    let isActive: Bool
    let settings: Settings
    let namespace: Namespace.ID

    var body: some View {
        VStack(spacing: 0) {
            WeekdayHeaderColumnsView(
                columns: weekdayColumns
            )

            GeometryReader { geo in
                let height = geo.size.height / 6

                if isActive {
                    CalendarMonthLoaderView(
                        datestamps: datestamps,
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
