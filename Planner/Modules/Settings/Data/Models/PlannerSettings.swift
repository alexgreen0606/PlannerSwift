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
    /// Maps calendar event IDs to system image names.
    var iconMap: [String: String] = [:]

    /// Set of calendar IDs to exclude from planners.
    var hiddenCalendarIds: Set<String> = []

    // MARK: Sibling
    /// Planners default to this location, else the current device location is used (not recommended).
    var homeLocation: Location?

    init() {}
}
