//
//  LocationExtension.swift
//  Planner
//
//  Created by Alex Green on 2/13/26.
//

import SwiftDate
import Foundation

extension Location {

    var key: String {
        coordinateKey(lat: self.latitude, long: self.longitude)
            + self.timeZoneIdentifier
    }

    var region: Region? {
        guard let timeZone = TimeZone(identifier: self.timeZoneIdentifier)
        else {
            assertionFailure(
                "ERROR LocationExtension.region: Could not create a TimeZone from: \(self.timeZoneIdentifier)"
            )
            return nil
        }
        
        return Region(
            calendar: Calendar.current,
            zone: timeZone,
            locale: Locale.current
        )
    }
}
