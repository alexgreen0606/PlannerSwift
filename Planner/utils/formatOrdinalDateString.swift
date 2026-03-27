//
//  formatOrdinalDateString.swift
//  Planner
//
//  Created by Alex Green on 3/26/26.
//

// Note: Any strings with a comma MUST be of format MMM DD, YYYY
func formatOrdinalDateString(_ text: String) -> String {
    var formatted = text

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

    return formatted
}
