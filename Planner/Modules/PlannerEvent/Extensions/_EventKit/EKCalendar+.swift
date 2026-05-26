//
//  EKCalendar+.swift
//  Planner
//
//  Created by Alex Green on 12/21/25.
//

import EventKit
import SwiftUI

extension EKCalendar {
    var color: Color {
        Color(cgColor: cgColor)
    }

    func systemImageName(settings: PlannerSettings) -> String {
        if let customSystemImage = settings.iconMap[
            calendarIdentifier
        ] {
            return customSystemImage
        }

        let lowercaseTitle = title.lowercased()

        // Default birthday icon.
        if lowercaseTitle.contains("birthday") {
            return "birthday.cake.fill"
        }

        // Default holiday icon.
        if lowercaseTitle.contains("holiday") {
            return "globe.americas.fill"
        }

        return "calendar"
    }

    func isHidden(filteredCalendarIds: Set<String>?) -> Bool {
        guard let filteredCalendarIds, !filteredCalendarIds.isEmpty else {
            return false
        }

        return !filteredCalendarIds.contains(
            calendarIdentifier
        )
    }
}
