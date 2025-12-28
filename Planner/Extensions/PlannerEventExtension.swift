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
    func timeValueView(for datestamp: String, openSheet: @escaping (PlannerEvent, String) -> Void, animation: Namespace.ID) -> some View {
        Group {
            if let date = self.date {
                let (timeValue, indicator) = date.timeValues

                let calendarEventColor = self.calendarEvent?.calendar.cgColor
                let color =
                    calendarEventColor != nil
                    ? Color(calendarEventColor!) : .blue
                
                let transitionId = self.calendarEvent != nil ? String(describing: self.calendarEvent!.eventIdentifier) : String(describing: self.id)
                
                // TODO: determine start or end

                TimeValue(
                    time: timeValue,
                    indicator: indicator,
                    detail: nil,
                    disabled: false,
                    color: color
                ) {
                    openSheet(self, "TimeValue")
                }
                .matchedTransitionSource(
                    id: "\(transitionId)_TimeValue",
                    in: animation
                )
            } else {
                EmptyView()
            }
        }
    }
}
