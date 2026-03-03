//
//  PlannerSettingsExtension.swift
//  Planner
//
//  Created by Alex Green on 2/14/26.
//

import EventKit
import SwiftDate
import SwiftUI

extension PlannerSettings {

    var homeRegion: Region {
        homeLocation?.region ?? .local
    }

    // Only ever nil if the device location is loading.
    func validHomeLocation(deviceLocation: Location?) -> Location? {
        homeLocation ?? deviceLocation
    }

    func homeLocationLabel(localCityName: String) -> String {
        homeLocation?.name ?? localCityName
    }

    var homeLocationIconConfig: IconConfig {
        IconConfig(
            name: homeLocation != nil ? "house" : "location"
        )
    }

}
