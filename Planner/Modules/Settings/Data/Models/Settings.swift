//
//  Settings.swift
//  Planner
//
//  Created by Alex Green on 1/4/26.
//

import SwiftData
import SwiftUI

@Model
class Settings {

    var showListDividers: Bool = true

    /// ToggleTransitionDuration rawValue
    var toggleTransitionDurationRawValue: String = ToggleTransitionDuration
        .oneSecond.rawValue

    /// KeepPastEventsDuration rawValue
    var keepPastEventsDurationRawValue: String = KeepPastEventsDuration
        .oneMonth.rawValue

    /// Maps calendar IDs to system image names.
    var calendarIconMap: [String: String] = [:]

    /// Set of calendar IDs to exclude from planners.
    var hiddenCalendarIds: Set<String> = []

    // MARK: Sibling
    /// Planners default to this location, else the current device location is used (not recommended).
    var homeLocation: Location?

    init() {}
}
