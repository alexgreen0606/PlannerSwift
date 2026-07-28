//
//  LocationContext.swift
//  Planner
//
//  Created by Alex Green on 7/28/26.
//

enum LocationContext: Identifiable {
    case home(Location)
    case trip(Location)
    case event(Location)
    case current

    var id: String {
        switch self {
        case .home(let location),
            .trip(let location),
            .event(let location):
            return String(describing: location.id)
        case .current:
            return "CURRENT"
        }
    }

    var location: Location? {
        switch self {
        case .home(let location),
            .trip(let location),
            .event(let location):
            return location
        case .current:
            return nil
        }
    }

    var displayLocationName: Bool {
        switch self {
        case .home, .current:
            return false
        case .event, .trip:
            return true
        }
    }

    func iconConfig(event: PlannerEvent, accentColor: AccentColor)
        -> IconConfig?
    {
        switch self {
        case .home:
            return IconConfig(name: "house")
        case .current:
            return IconConfig(name: "location")
        case .event:
            return IconConfig(
                name: "mappin.and.ellipse",
                primaryColor: event.tint(
                    accentColor: accentColor
                )
            )
        case .trip:
            return IconConfig(name: "suitcase")
        }
    }
}
