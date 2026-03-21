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

    func checkedFooter(for plannerDay: DateInRegion) -> String? {
        switch self {
        case .pastOrPresent:
            return nil

        case .future:

            var formatted = plannerDay.dynamicTitle

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

            // TODO: dont show this if setting is disabled.

            let displayDate: String =
                formatted.rangeOfCharacter(from: .decimalDigits) == nil
                ? "\(formatted) morning"
                : "the morning of \(formatted)"

            return
                "These canceled events will be deleted \(displayDate). Calendar events will not be deleted."
        }
    }

    // MARK: - Helper Variables

    private var checkedLabel: String {
        switch self {
        case .pastOrPresent: "completed"
        case .future: "canceled"
        }
    }

}
