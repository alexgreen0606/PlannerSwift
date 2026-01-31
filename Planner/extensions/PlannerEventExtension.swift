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
        openSheet: ((PlannerEvent) -> Void)?,
        accentColor: Color
    ) -> some View {
        Group {
            if let calendarEvent = self.calendarEvent {
                calendarEvent.timeValueView(
                    for: datestamp,
                    openSheet: {
                        openSheet?(self)
                    }
                )

            } else if let date = self.date {

                TimeValue(
                    date: date,
                    datestamp: datestamp,
                    disabled: false,
                    color: accentColor
                ) {
                    openSheet?(self)
                }

            } else {
                EmptyView()
            }
        }
    }
}
