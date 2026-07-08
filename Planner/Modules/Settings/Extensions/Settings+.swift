//
//  Settings+.swift
//  Planner
//
//  Created by Alex Green on 2/14/26.
//

import EventKit
import SwiftDate
import SwiftUI

extension Settings {
    func homeLocation(deviceLocation: Location?) -> Location? {
        homeLocation ?? deviceLocation
    }

    var homeRegion: Region {
        homeLocation?.region ?? .local
    }

    func homeLocationLabel(deviceLocation: Location?) -> String {
        homeLocation(deviceLocation: deviceLocation)?.name ?? "Current Location"
    }

    var homeLocationIconConfig: IconConfig {
        IconConfig(
            name: homeLocation != nil ? "house" : "location"
        )
    }

    func isCalendarHidden(calendarId: String) -> Bool {
        hiddenCalendarIds.contains(
            calendarId
        )
    }

    func ensureDefaultCalendarIcon(calendar: EKCalendar) {
        let calendarIdentifier = calendar.calendarIdentifier

        guard calendarIconMap[calendarIdentifier] == nil else {
            return
        }

        // Default birthday calendar to cake icon.
        if calendar.type == .birthday {
            calendarIconMap[calendarIdentifier] =
                "birthday.cake.fill"
        }

        // Default holiday calendar to globe icon.
        if calendar.title.localizedCaseInsensitiveContains("holiday") {
            calendarIconMap[calendarIdentifier] = "globe.americas.fill"
        }
    }
}
