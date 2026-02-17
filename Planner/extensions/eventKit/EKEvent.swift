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

    // TODO: Start vs End
    func dateInRegion(region: Region) -> DateInRegion {
        DateInRegion(self.startDate, region: region)
    }

    func bottomAdornmentValues(
        plannerRegion: Region
    ) -> (location: String?, time: String?)? {

        // Location Label
        let location =
            structuredLocation?.title?.isEmpty == false
            ? structuredLocation?.title
            : nil

        // Time Label (only if event timezone differs from planner timezone)
        var timeString: String? = nil
        let eventRegion = region(fallback: plannerRegion)

        if eventRegion.timeZone.identifier != plannerRegion.timeZone.identifier {
            
            // TODO: Start vs End
            let dateInRegion = DateInRegion(startDate, region: eventRegion)
            timeString = dateInRegion.timeWithTimezone
        }

        if location == nil && timeString == nil {
            return nil
        }

        return (location, timeString)
    }

    @ViewBuilder
    func timeValueView(
        in plannerRegion: Region,
        usePlannerRegion: Bool = true,
        scale: Double = 1,
        openSheet: (() -> Void)?
    ) -> some View {

        // TODO: Start vs End

        let eventRegion =
            usePlannerRegion
            ? plannerRegion : self.region(fallback: plannerRegion)

        TimeValueView(
            day: DateInRegion(self.startDate, region: eventRegion),
            disabled: false,
            color: !usePlannerRegion ? .secondary : self.calendar.color,
            scale: scale,
            openEventSheet: openSheet
        )

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
