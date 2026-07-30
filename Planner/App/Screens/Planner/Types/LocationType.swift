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

    func shouldDisplayLocation(
        for event: PlannerEvent,
        planner: Planner,
        locationTimeZoneId: String,
        settings: Settings
    ) -> Bool {
        let plannerLocation = planner.location(settings: settings)

        switch self {
        case .home, .trip, .current:
            let eventIsTimed = event.time != nil
            let hasDifferentTimeThanPlanner = locationTimeZoneId != plannerLocation.timeZoneId
            
            return eventIsTimed && hasDifferentTimeThanPlanner
        case .event:
            let plannerCoordinateId = planner.location(settings: settings).coordinateId
            
            let eventCoordinateId = event.coordinateId(
                planner: planner,
                settings: settings
            )
            
            return eventCoordinateId != plannerCoordinateId
        }
    }

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
