//
//  CalendarMonthTab.swift
//  Planner
//
//  Created by Alex Green on 11/18/26.
//

import SwiftDate
import SwiftUI

struct CalendarMonthTabView: View {
    @Binding var contextCache: [String: StructuredPlannerPreviewContext]
    let monthstamp: String
    let datestamps: [String?]
    let weekdayColumns: [GridItem]
    let isScrolling: Bool
    let settings: Settings
    let namespace: Namespace.ID

    var body: some View {
        VStack(spacing: 0) {
            WeekdayHeaderColumnsView(
                columns: weekdayColumns
            )

            monthGrid
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    // MARK: - View Builders

    private var monthGrid: some View {
        GeometryReader { geo in
            LazyVGrid(columns: weekdayColumns, spacing: 0) {
                ForEach(datestamps, id: \.self) { datestamp in
                    if let datestamp {
                        CalendarPlannerPreviewView(
                            contextCache: $contextCache,
                            datestamp: datestamp,
                            isScrolling: isScrolling,
                            height: (geo.size.height - Layout.TOOLBAR_HEIGHT)
                                / 6,
                            settings: settings,
                            namespace: namespace
                        )
                    } else {
                        Color.clear
                    }
                }
            }
        }
    }
}
