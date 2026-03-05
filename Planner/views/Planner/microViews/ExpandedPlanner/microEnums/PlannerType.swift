//
//  PlannerType.swift
//  Planner
//
//  Created by Alex Green on 1/20/26.
//

import Foundation
import SwiftDate

enum PlannerType: String {
    case pastOrPresent
    case future

    var emptyCheckedLabel: String {
        switch self {
        case .pastOrPresent: "No completed plans"
        case .future: "No canceled plans"
        }
    }

    var checkedHeader: String {
        switch self {
        case .pastOrPresent: "Completed plans"
        case .future: "Cancelled plans"
        }
    }

    var deleteCheckedLabel: String {
        switch self {
        case .pastOrPresent: "Delete completed plans"
        case .future: "Delete canceled plans"
        }
    }

    var deleteCheckedConfirmationTitle: String {
        switch self {
        case .pastOrPresent: "Delete completed plans from this planner?"
        case .future: "Delete canceled plans from this planner?"
        }
    }

    func getCheckedFooter(for startOfDay: DateInRegion) -> String? {
        switch self {
        case .pastOrPresent:
            return nil

        case .future:

            var formatted = startOfDay.dynamicHeader

            if !formatted.contains(",") {
                if let dayString = formatted.split(separator: " ").last,
                    let day = Int(dayString)
                {

                    let suffix: String
                    switch day % 100 {
                    case 11, 12, 13:
                        suffix = "th"
                    default:
                        switch day % 10 {
                        case 1: suffix = "st"
                        case 2: suffix = "nd"
                        case 3: suffix = "rd"
                        default: suffix = "th"
                        }
                    }

                    formatted += suffix
                }
            }

            let displayDate: String =
                formatted.rangeOfCharacter(from: .decimalDigits) == nil
                ? "\(formatted) morning"
                : "the morning of \(formatted)"

            return
                "These canceled plans will be deleted \(displayDate). Hidden calendar events will not be deleted."
        }
    }

    func getToggleVisibilityLabel(_ showHidden: Bool) -> String {
        switch self {
        case .pastOrPresent: showHidden ? "Hide completed" : "Show completed"
        case .future: showHidden ? "Hide canceled" : "Show canceled"
        }
    }
}
