//
//  PlannerType.swift
//  Planner
//
//  Created by Alex Green on 1/20/26.
//

import Foundation
import SwiftDate

// Clean

enum PlannerType: String {
    case pastOrPresent
    case future

    var emptyCheckedLabel: String {
        "No \(checkedLabel) events"
    }

    var checkedHeader: String {
        "\(checkedLabel.capitalized) events"
    }

    func toggleCheckedLabel(_ showChecked: Bool) -> String {
        showChecked ? "Hide \(checkedLabel)" : "Show \(checkedLabel)"
    }

    func checkedFooter(
        for datestamp: String,
        todaystamp: String,
        keepCanceledEvents: KeepCanceledEventsDuration,
        hasCalendarAccess: Bool
    ) -> String? {
        guard keepCanceledEvents != .forever, self != .pastOrPresent else {
            return nil
        }

        let formatted = datestamp.proximityFormat(
            using: [
                ProximityRule(
                    proximity: .withinADay,
                    format: .countdown,
                    ordinal: true
                ),
                ProximityRule(proximity: .next7Days, format: .weekday),
                ProximityRule(
                    proximity: .fallback,
                    format: .dateLabel,
                    ordinal: true
                ),
            ],
            todaystamp: todaystamp
        )

        let displayDate: String =
            formatted.rangeOfCharacter(from: .decimalDigits) == nil
            ? "\(formatted) morning"
            : "the morning of \(formatted)"

        return
            "These canceled events will be deleted \(displayDate).\(hasCalendarAccess ? " Calendar events will not be deleted." : "")"
    }

    // MARK: - Helper Variables

    private var checkedLabel: String {
        switch self {
        case .pastOrPresent: "completed"
        case .future: "canceled"
        }
    }

}
