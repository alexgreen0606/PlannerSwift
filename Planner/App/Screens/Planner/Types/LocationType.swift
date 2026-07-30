//
//  LocationType.swift
//  Planner
//
//  Created by Alex Green on 7/28/26.
//

import Foundation

enum LocationType {
    case home
    case trip
    case event
    case current

    func iconConfig(event: PlannerEvent, accentColor: AccentColor)
        -> IconConfig
    {
        switch self {
        case .home:
            return IconConfig(name: "house")
        case .trip:
            return IconConfig(name: "suitcase")
        case .event:
            return IconConfig(
                name: "mappin.and.ellipse",
                primaryColor: event.tint(
                    accentColor: accentColor
                )
            )
        case .current:
            return IconConfig(name: "location")
        }
    }
}
