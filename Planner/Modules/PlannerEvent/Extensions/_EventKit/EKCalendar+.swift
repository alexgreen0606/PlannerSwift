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
        settings.ensureDefaultCalendarIcon(calendar: self)

        return settings.calendarIconMap[
            calendarIdentifier
        ] ?? "calendar"
    }
}
