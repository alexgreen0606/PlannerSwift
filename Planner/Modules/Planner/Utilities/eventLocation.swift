//
//  eventLocation.swift
//  Planner
//
//  Created by Alex Green on 2/24/26.
//

/// Determined by priority: Event Location else -> Planner Location else ->  Trip Location else -> Home Location else -> Device Location
func eventLocation(
    location: Location?,
    planner: Planner?,
    settings: PlannerSettings,
    deviceLocation: Location?
) -> // Note: Only nil if the device location has not loaded in.
    Location?
{
    location
        ?? planner?.location(
            settings: settings,
            deviceLocation: deviceLocation
        )
}
