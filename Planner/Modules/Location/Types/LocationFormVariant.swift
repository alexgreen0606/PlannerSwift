//
//  LocationFormVariant.swift
//  Planner
//
//  Created by Alex Green on 5/30/26.
//

enum LocationFormVariant {
    case home
    case trip
    case planner
    case event

    var title: String {
        switch self {
        case .home: return "Home Location"
        case .trip: return "Trip Location"
        case .planner: return "Planner Location"
        case .event: return "Event Location"
        }
    }
}
