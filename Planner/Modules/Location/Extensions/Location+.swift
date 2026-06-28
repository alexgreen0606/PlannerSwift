//
//  Location+.swift
//  Planner
//
//  Created by Alex Green on 2/13/26.
//

import MapKit
import SwiftDate

extension Location {
    var safeTrips: [Trip] {
        trips ?? []
    }

    var safePlanners: [Planner] {
        planners ?? []
    }

    var safePlannerEvents: [PlannerEvent] {
        plannerEvents ?? []
    }

    var coordinateId: String {
        CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        ).id
    }

    var nameId: String {
        "\(name)-\(subtitle ?? "")"
    }

    var region: Region {
        let timeZone =
            TimeZone(identifier: timeZoneIdentifier)
                ?? {
                    assertionFailure(
                        "ERROR Location+ region: Could not create a TimeZone from identifier \(timeZoneIdentifier)"
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
