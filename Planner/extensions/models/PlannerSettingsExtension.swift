//
//  PlannerSettingsExtension.swift
//  Planner
//
//  Created by Alex Green on 2/14/26.
//

import EventKit
import SwiftDate
import SwiftUI

// Clean

extension PlannerSettings {

    var homeRegion: Region {
        self.homeLocation?.region ?? .local
    }

    var homeLocationLabel: String {
        homeLocation?.name ?? "Current Location"
    }

    func homeLocation(deviceLocation: Location?) -> Location? {
        homeLocation ?? deviceLocation  // nil means the current device location is used and hasn't loaded yet
    }

    var homeLocationIconConfig: IconConfig {
        IconConfig(
            name: homeLocation != nil ? "house" : "location"
        )
    }

}
