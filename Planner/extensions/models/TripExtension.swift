//
//  TripExtension.swift
//  Planner
//
//  Created by Alex Green on 3/22/26.
//

import Foundation
import SwiftDate

// Clean

extension Trip {
    
    var sortedDatestamps: [String] {
        sortedDays.map { $0.datestamp }
    }

    var dateComponents: Set<DateComponents> {
        Set(
            sortedDays.map { day in
                Calendar.current.dateComponents(
                    [.year, .month, .day],
                    from: day.date
                )
            }
        )
    }

    func plannerTransitionId(for datestamp: String) -> String {
        "\(datestamp)_\(String(describing: id))"
    }

    var cancelWarning: String {
        var message =
            "Existing events will not be affected. This action is irreversible."

        let needsLocationWarning = self.location != nil
        let needsRoutinesMessage = self.hideRoutines

        if needsLocationWarning {
            let locationMessage =
                "\(needsRoutinesMessage ? "p" : "P")lanner locations will \(needsRoutinesMessage ? "restore" : "be restored") to your home location. "
            message = locationMessage + message
        }

        if needsRoutinesMessage {
            let routinesMessage =
                "Routines will be turned back on\(needsLocationWarning ? " and " : ". ")"
            message = routinesMessage + message
        }

        return message
    }

    // MARK: - Helper Variables

    private var sortedDays: [DateInRegion] {

        guard
            var current = DateInRegion(startDatestamp, region: .local)?
                .dateAtStartOf(.day)
        else {
            return []
        }

        guard
            let end = DateInRegion(endDatestamp, region: .local)?.dateAtEndOf(
                .day
            )
        else {
            return []
        }

        var days: [DateInRegion] = []
        while current <= end {
            days.append(current)
            current = current + 1.days
        }

        return days
    }

}
