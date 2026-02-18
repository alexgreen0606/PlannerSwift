//
//  CLLocationCoordinate2D.swift
//  Planner
//
//  Created by Alex Green on 2/18/26.
//

import MapKit

extension CLLocationCoordinate2D {
    
    var key: String {
        "\(self.latitude),\(self.longitude)"
    }
    
}
