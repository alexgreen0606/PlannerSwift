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

    func tint(accentColor: AccentColor) -> Color {
        if let calendar = self.calendarEvent?.calendar {
            return calendar.color
        }

        return accentColor.swiftUIColor
    }

    func handleTitleChange(
        startOfDay: DateInRegion,
        eventKitStore: EKEventStore
    ) {

        // Case 1: Update the device calendar with the new title.
        guard self.calendarEvent == nil else {
            self.calendarEvent!.title = self.title

            do {
                try eventKitStore.save(
                    self.calendarEvent!,
                    span: .thisEvent
                )
            } catch {
                assertionFailure(
                    "ERROR PlannerEventExtension.handleTitleChange: \(error)"
                )
            }

            return
        }

        // Case 2: Scan the new title for a time value.
        guard
            let (timeValue, updatedText) = self.title.separateTimeValue()
        else {
            return
        }

        guard
            let date = timeValue.toDate(
                for: startOfDay
            )
        else {
            return
        }

        self.title = updatedText
        self.hasTime = true

        // Change the event's date, but preserve its sort position.
        self.date = date

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

        } else if self.hasTime {

            TimeValueView(
                day: DateInRegion(self.date, region: region),
                disabled: false,
                color: accentColor,
                scale: 1,
                openEventSheet: openSheet
            )

        }
    }

}
