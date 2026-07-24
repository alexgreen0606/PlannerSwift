//
//  PlannerEventLocationAdornment.swift
//  Planner
//
//  Created by Alex Green on 2/27/26.
//

import SwiftDate
import SwiftUI

struct PlannerEventLocationAdornmentView: View {
    let plannerEvent: PlannerEvent
    let planner: Planner
    let settings: Settings
    let openEventSheet: () -> Void

    private let SCALE: CGFloat = 0.65

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @EnvironmentObject private var locationService: LocationService

    private var plannerTimeZoneIdentifier: String {
        planner.region(settings: settings)
            .timeZone.identifier
    }

    private var eventLocationLabel: String? {
        let plannerLocationLabel = planner.locationLabel(
            settings: settings,
            deviceLocation: locationService.deviceLocation
        )

        let eventLocationLabel = plannerEvent.locationLabel(
            planner: planner,
            settings: settings,
            deviceLocation: locationService.deviceLocation
        )

        guard eventLocationLabel != plannerLocationLabel else {
            return nil
        }

        return eventLocationLabel
    }

    private var locationTimeLabel: String? {
        let eventRegion = plannerEvent.region(
            planner: planner,
            settings: settings,
            deviceLocation: locationService.deviceLocation
        )

        let eventTimeZoneIdentifier = eventRegion.timeZone.identifier

        if eventTimeZoneIdentifier != plannerTimeZoneIdentifier,
            let time = plannerEvent.time
        {
            return DateInRegion(
                time,
                region: eventRegion
            ).timeString
        }

        return nil
    }

    private var homeTimeLabel: String? {
        guard
            let homeLocation = settings.homeLocation
        else { return nil }
        
        let homeRegion = homeLocation.region
        let homeTimeZoneIdentifier = homeLocation.timeZoneIdentifier

        if plannerTimeZoneIdentifier != homeTimeZoneIdentifier,
            let time = plannerEvent.time
        {
            // Display the home time if it differs from the planner's time.
            return DateInRegion(
                time,
                region: homeRegion
            ).timeString
        }

        return nil
    }

    // MARK: - Body

    var body: some View {
        Grid(horizontalSpacing: 6, verticalSpacing: 4) {
            if eventLocationLabel != nil || locationTimeLabel != nil {
                GridRow {
                    if let eventLocationLabel {
                        AdornedValue(
                            eventLocationLabel,
                            iconConfig: IconConfig(
                                name: "mappin.and.ellipse",
                                primaryColor: plannerEvent.tint(
                                    accentColor: accentColor
                                )
                            ),
                            color: .secondary,
                            scale: SCALE
                        )
                        .gridColumnAlignment(.trailing)
                    }

                    if let locationTimeLabel {
                        Value(
                            locationTimeLabel,
                            color: .secondary,
                            scale: SCALE
                        )
                    }
                }
            }

            if let homeTimeLabel {
                GridRow {
                    AdornedValue(
                        nil,
                        iconConfig: IconConfig(name: "house"),
                        color: .secondary,
                        scale: SCALE
                    )
                    .gridColumnAlignment(.trailing)

                    Value(homeTimeLabel, color: .secondary, scale: SCALE)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
