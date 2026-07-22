//
//  Optional+CoordinateId.swift
//  Planner
//
//  Created by Alex Green on 7/17/26.
//

import CoreLocation

extension Optional where Wrapped: Location {
    func coordinateId(deviceCLLocation: CLLocation?) -> String? {
        self?.coordinateId ?? deviceCLLocation?.coordinate.id
    }
}
