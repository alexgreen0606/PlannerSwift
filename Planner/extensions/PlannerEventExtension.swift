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
        animation: Namespace.ID?
    ) -> some View {
        Group {
            if self.calendarEvent != nil {
                self.calendarEvent!.timeValueView(
                    for: datestamp,
                    openEventSheet: openCalendarEventSheet,
                    animation: animation
                )

            } else if let date = self.date {
                let validOpenEventSheet =
                    openPlannerEventSheet != nil
                    ? {
                        openPlannerEventSheet!(self)
                    } : nil

                let timeVal = TimeValue(
                    date: date,
                    datestamp: datestamp,
                    disabled: false,
                    color: .blue,
                    openEventSheet: validOpenEventSheet
                )

                if validOpenEventSheet == nil || animation == nil {
                    timeVal
                } else {
                    timeVal
                        .matchedTransitionSource(
                            id: String(describing: self.id),
                            in: animation!
                        )
                }

            } else {
                EmptyView()
            }
        }
    }
}
