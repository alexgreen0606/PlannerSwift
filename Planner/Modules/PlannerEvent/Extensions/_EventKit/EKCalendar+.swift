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

        if type == .birthday {
            // Default birthday icon.
            return "birthday.cake.fill"
        }

        if title.localizedCaseInsensitiveContains("holiday") {
            // Default holiday icon.
            return "globe.americas.fill"
        }

        return "calendar"
    }
}
