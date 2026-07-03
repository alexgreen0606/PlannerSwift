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
    
    func systemImageName(settings: Settings) -> String {
        if let customSystemImage = settings.calendarIconMap[
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
