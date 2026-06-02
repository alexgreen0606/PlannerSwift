//
//  CLLocationCoordinate2D+ID.swift
//  Planner
//
//  Created by Alex Green on 2/18/26.
//

import MapKit

extension CLLocationCoordinate2D {
    var id: String {
        "\(latitude),\(longitude)"
    }
}
