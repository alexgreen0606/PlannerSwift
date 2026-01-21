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
        animation: Namespace.ID?,
        accentColor: Color
    ) -> some View {
        Group {
            if let calendarEvent = self.calendarEvent {
                calendarEvent.timeValueView(
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
                    color: accentColor,
                    openEventSheet: validOpenEventSheet
                )

                if validOpenEventSheet != nil, let animation {
                    timeVal
                        .matchedTransitionSource(
                            id: String(describing: self.id),
                            in: animation
                        )
                } else {
                    timeVal
                }

            } else {
                EmptyView()
            }
        }
    }
}
