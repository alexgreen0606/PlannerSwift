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
    
    func timeZone(fallback: TimeZone) -> TimeZone {
        self.calendarEvent?.timeZone ?? fallback
    }

    func tint(accentColor: AccentColor) -> Color {
        if let calendar = self.calendarEvent?.calendar {
            return calendar.color
        }

        return accentColor.swiftUIColor
    }

    @ViewBuilder
    func timeValueView(
        in region: Region,
        accentColor: Color,
        openSheet: (() -> Void)?
    ) -> some View {
        if let calendarEvent = self.calendarEvent {

            calendarEvent.timeValueView(
                in: region,
                openSheet: openSheet
            )

        } else if !self.untimed {

            TimeValueView(
                day: DateInRegion(self.date, region: region),
                disabled: false,
                color: accentColor,
                scale: 1,
                openEventSheet:  openSheet
            )

        }
    }

}
