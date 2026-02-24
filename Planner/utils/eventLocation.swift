//
//  eventLocation.swift
//  Planner
//
//  Created by Alex Green on 2/24/26.
//

func eventLocation(
    locationSource: LocationSource,
    location: Location?,
    planner: Planner?,
    settings: PlannerSettings
) -> Location? {
    switch locationSource {
    case .custom:
        guard let location else {
            fatalError(
                "ERROR eventLocation.location: Event is set to custom location but no location is set."
            )
        }

        return location
    case .planner:
        guard let planner else {
            fatalError(
                "ERROR eventLocation.location: Event is set to planner location but no planner was passed."
            )
        }

        return planner.location(settings: settings)
    case .home:
        return settings.homeLocation
    case .current:
        return nil
    }
}
