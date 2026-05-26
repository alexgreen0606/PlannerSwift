//
//  Location+.swift
//  Planner
//
//  Created by Alex Green on 2/13/26.
//

import Foundation
import MapKit
import SwiftDate

// Clean

extension Location {
    var safeTrips: [Trip] {
        trips ?? []
    }

    var safePlanners: [Planner] {
        planners ?? []
    }

    var safeEvents: [PlannerEvent] {
        events ?? []
    }

    var coordinateKey: String {
        CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        ).key
    }
    
    var nameKey: String {
        "\(name)-\(String(describing: subtitle))"
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
