//
//  LocationExtension.swift
//  Planner
//
//  Created by Alex Green on 2/13/26.
//

import Foundation
import MapKit
import SwiftDate

// Clean

extension Location {

    var coordinateKey: String {
        CLLocationCoordinate2D(
            latitude: self.latitude,
            longitude: self.longitude
        ).key
    }

    var region: Region {
        let timeZone =
            TimeZone(identifier: timeZoneIdentifier)
            ?? {
                assertionFailure(
                    "ERROR LocationExtension.region: Could not create a TimeZone from \(timeZoneIdentifier)"
                )
                return TimeZone.current
            }()

        return Region(
            calendar: Calendar.current,
            zone: timeZone,
            locale: Locale.current
        )
    }

}
