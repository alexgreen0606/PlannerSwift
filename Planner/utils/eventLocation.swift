//
//  eventLocation.swift
//  Planner
//
//  Created by Alex Green on 2/24/26.
//

// Nil means the device location has not loaded in.
func eventLocation(
    location: Location?,
    planner: Planner?,
    settings: PlannerSettings,
    deviceLocation: Location?
) -> Location? {  // Priority: Event Location -> Planner Location -> Home Location -> Device Location
    location ?? planner?.location(
        settings: settings,
        deviceLocation: deviceLocation
    ) ?? deviceLocation
}
