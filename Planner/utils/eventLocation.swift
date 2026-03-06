//
//  eventLocation.swift
//  Planner
//
//  Created by Alex Green on 2/24/26.
//

// Clean

// Priority: Event Location -> Planner Location -> Home Location -> Device Location
// Only nil if the device location has not loaded in.
func eventLocation(
    location: Location?,
    planner: Planner?,
    settings: PlannerSettings,
    deviceLocation: Location?
) -> Location? {
    location ?? planner?.location(
        settings: settings,
        deviceLocation: deviceLocation
    ) ?? settings.homeLocation(deviceLocation: deviceLocation)
}
