//
//  MKLocalSearchCompletion+ID.swift
//  Planner
//
//  Created by Alex Green on 3/10/26.
//

import MapKit

extension MKLocalSearchCompletion {
    /// Note: This MUST always match the nameId in Location+
    var nameId: String {
        "\(title)-\(subtitle)"
    }
}
