//
//  _PlannerSettings.swift
//  Planner
//
//  Created by Alex Green on 2/14/26.
//

import EventKit
import SwiftDate
import SwiftUI

// Clean

extension PlannerSettings {

    func homeLocation(deviceLocation: Location?) -> Location?  // nil means the current device location is used and hasn't loaded yet
    {
        homeLocation ?? deviceLocation
    }

    var homeRegion: Region {
        self.homeLocation?.region ?? .local
    }

    func homeLocationLabel(deviceLocation: Location?) -> String {
        homeLocation(deviceLocation: deviceLocation)?.name ?? "Current Location"
    }

    var homeLocationIconConfig: IconConfig {
        IconConfig(
            name: self.homeLocation != nil ? "house" : "location"
        )
    }

}
