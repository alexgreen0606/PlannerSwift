//
//  LocationExtension.swift
//  Planner
//
//  Created by Alex Green on 2/13/26.
//

extension Location {

    var key: String {
        coordinateKey(lat: self.latitude, long: self.longitude)
    }

}
