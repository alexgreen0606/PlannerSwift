//
//  MKLocalSearchCompletion+ID.swift
//  Planner
//
//  Created by Alex Green on 3/10/26.
//

import MapKit

// Clean

extension MKLocalSearchCompletion {
    var id: String {
        "\(title)-\(subtitle)"
    }
}
