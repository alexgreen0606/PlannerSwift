//
//  PlannerExtension.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import Fuse
import SwiftDate
import SwiftUI

// Clean

extension Planner {

    var key: String {
        let locationKey = location?.coordinateKey ?? "HOME_LOCATION"
        return "\(datestamp)-\(locationKey)"
    }

    // MARK: - Location Variables

    // Nil means the device location is used and hasn't loaded yet.
    func location(settings: PlannerSettings, deviceLocation: Location?)
        -> Location?
    {
        self.location ?? self.trip?.location
            ?? settings.homeLocation(deviceLocation: deviceLocation)
    }

    func region(settings: PlannerSettings) -> Region {
        location?.region ?? settings.homeRegion
    }

    func locationLabel(settings: PlannerSettings, deviceLocation: Location?)
        -> String
    {
        location(settings: settings, deviceLocation: deviceLocation)?.name
            ?? "Current Location"
    }

    func locationIconConfig(settings: PlannerSettings, accentColor: AccentColor)
        -> IconConfig
    {
        if self.location != nil {
            return IconConfig(
                name: "mappin.and.ellipse",
                primaryColor: accentColor.color
            )
        }
        
        if self.trip != nil {
            return IconConfig(
                name: "suitcase"
            )
        }

        return settings.homeLocationIconConfig
    }

    func searchQueryScore(_ query: PlannerSearchQuery?) -> Double? {
        guard let query else {
            // Include when no query is set.
            return 1.0
        }

        if query.filterPast && self.datestamp >= query.todayStartOfDay.datestamp
        {
            // Exclude if it doesnt match the time range.
            return nil
        }

        if !query.filterPast && self.datestamp < query.todayStartOfDay.datestamp
        {
            // Exclude if it doesnt match the time range.
            return nil
        }

        if query.text.isEmpty {
            // Include if there is no search text.
            return 1.0
        }

        if let location = self.location,
            let results = query.fuse.search(query.text, in: location.name),
            results.score <= FuseConstants.fuzzyThreshold
        {
            // Include if the location matches the search text.
            return 1 - results.score
        }

        return nil
    }

}
