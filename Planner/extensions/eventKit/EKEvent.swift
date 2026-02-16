//
//  EKEvent.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import SwiftDate
import SwiftUI

extension EKEvent {

    var transitionId: String {
        "\(String(describing: self.eventIdentifier))"
    }

    @ViewBuilder
    func timeValueView(
        in plannerRegion: Region,
        openSheet: (() -> Void)?
    ) -> some View {

        // TODO: determine if start or end date

        let eventRegion = self.region(fallback: plannerRegion)

        TimeValue(
            day: DateInRegion(self.startDate, region: eventRegion),
            disabled: false,
            color: Color(self.calendar.cgColor)
        ) {
            openSheet?()
        }

    }

    func region(fallback: Region) -> Region {
        
        // TODO: is this true???
        // Note: Event start and end may be in different timezones.
        // As of now, Apple does not provide access to these different timezones.
        
        if let timeZone = self.timeZone {
            return Region(
                calendar: fallback.calendar,
                zone: timeZone,
                locale: fallback.locale
            )
        } else {
            return fallback
        }
    }

}
