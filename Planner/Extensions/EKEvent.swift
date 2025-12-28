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
    func timeValueView(for datestamp: String, openSheet: @escaping (EKEvent, String) -> Void, animation: Namespace.ID, key: String) -> some View {
        let (timeValue, indicator) = self.startDate
            .timeValues

        // TODO: determine if start or end date based on datestamp

        TimeValue(
            time: timeValue,
            indicator: indicator,
            detail: nil,
            disabled: false,
            color: Color(self.calendar.cgColor)
        ) {
            openSheet(self, "TimeValue_\(key)")
        }
        .matchedTransitionSource(
            id: "\(String(describing: self.eventIdentifier))_TimeValue_\(key)",
            in: animation
        )
    }
}
