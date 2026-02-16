//
//  PlannerEventExtension.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import SwiftDate
import SwiftUI

extension PlannerEvent {

    // TODO: is this needed?
//    var time: Date? {
//        if let calEvent = self.calendarEvent {
//
//            // TODO: DETERMINE START OR END DATE BASED ON EVENT.DATE
//
//            return calEvent.startDate
//        }
//
//        return untimed ? nil : self.date
//    }

    func tint(accentColor: AccentColor) -> Color {
        if let calendar = self.calendarEvent?.calendar {
            return calendar.color
        }

        return accentColor.swiftUIColor
    }

    @ViewBuilder
    func timeValueView(
        in region: Region,
        openSheet: ((PlannerEvent) -> Void)?,
        accentColor: Color
    ) -> some View {
        if let calendarEvent = self.calendarEvent {

            calendarEvent.timeValueView(
                in: region
            ) {
                openSheet?(self)
            }

        } else if !self.untimed {

            TimeValue(
                day: DateInRegion(self.date, region: region),
                disabled: false,
                color: accentColor
            ) {
                openSheet?(self)
            }

        }
    }

}
