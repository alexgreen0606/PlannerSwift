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
        openPlannerEventSheet: @escaping (PlannerEvent) -> Void,
        openCalendarEventSheet: @escaping (EKEvent) -> Void,
        animation: Namespace.ID
    ) -> some View {
        Group {
            if self.calendarEvent != nil {
                self.calendarEvent!.timeValueView(
                    for: datestamp,
                    openEventSheet: openCalendarEventSheet,
                    animation: animation
                )

            } else if let date = self.date {
                TimeValue(
                    date: date,
                    datestamp: datestamp,
                    disabled: false,
                    color: .blue
                ) {
                    openPlannerEventSheet(self)
                }
                .matchedTransitionSource(
                    id: String(describing: self.id),
                    in: animation
                )

            } else {
                EmptyView()
            }
        }
    }
}
