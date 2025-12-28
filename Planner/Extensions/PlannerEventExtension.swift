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
    func timeValueView(for datestamp: String) -> some View {
        Group {
            if let date = self.date {
                let (timeValue, indicator) = date.timeValues

                let calendarEventColor = self.calendarEvent?.calendar.cgColor
                let color =
                    calendarEventColor != nil
                    ? Color(calendarEventColor!) : .blue
                
                // TODO: determine start or end

                TimeValue(
                    time: timeValue,
                    indicator: indicator,
                    detail: nil,
                    disabled: false,
                    color: color
                ) {
                    // TODO: open time modal
                }
            } else {
                EmptyView()
            }
        }
    }
}
