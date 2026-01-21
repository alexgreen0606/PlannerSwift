//
//  EKEvent.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import SwiftUI

extension EKEvent {
    @ViewBuilder
    func timeValueView(
        for datestamp: String,
        openEventSheet: ((EKEvent) -> Void)?,
        animation: Namespace.ID?
    ) -> some View {
        
        let validOpenEventSheet =
            openEventSheet != nil
            ? {
                openEventSheet!(self)
            } : nil

        // TODO: determine if start or end date

        let timeVal = TimeValue(
            date: self.startDate,
            datestamp: datestamp,
            disabled: false,
            color: Color(self.calendar.cgColor),
            openEventSheet: validOpenEventSheet
        )

        if openEventSheet != nil, let animation {
            timeVal
                .matchedTransitionSource(
                    id:
                        "\(String(describing: self.eventIdentifier))-\(animation)-\(self.isAllDay)",
                    in: animation
                )
        } else {
            timeVal
        }
    }
}
