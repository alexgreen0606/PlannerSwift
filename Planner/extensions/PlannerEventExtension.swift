//
//  PlannerEventExtension.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import SwiftUI

extension PlannerEvent {
    @ViewBuilder
    func timeValueView(
        for datestamp: String,
        openPlannerEventSheet: ((PlannerEvent) -> Void)?,
        openCalendarEventSheet: ((EKEvent) -> Void)?,
        accentColor: Color
    ) -> some View {
        Group {
            if let calendarEvent = self.calendarEvent {
                calendarEvent.timeValueView(
                    for: datestamp,
                    openEventSheet: openCalendarEventSheet
                )

            } else if let date = self.date {

                TimeValue(
                    date: date,
                    datestamp: datestamp,
                    disabled: false,
                    color: accentColor
                ) {
                    openPlannerEventSheet?(self)
                }

            } else {
                EmptyView()
            }
        }
    }
}
