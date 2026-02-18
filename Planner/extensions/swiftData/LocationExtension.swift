//
//  LocationExtension.swift
//  Planner
//
//  Created by Alex Green on 2/13/26.
//

import Foundation
import MapKit
import SwiftDate

extension Location {

    var coordinateKey: String {
        CLLocationCoordinate2D(
            latitude: self.latitude,
            longitude: self.longitude
        ).key
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
