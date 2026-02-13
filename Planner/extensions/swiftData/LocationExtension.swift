//
//  LocationExtension.swift
//  Planner
//
//  Created by Alex Green on 2/13/26.
//

extension Location {

    var key: String {
        let lat = self.latitude.roundDecimals(to: 4)
        let lon = self.longitude.roundDecimals(to: 4)

        return "\(lat),\(lon)"
    }

}
