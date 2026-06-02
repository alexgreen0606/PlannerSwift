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
    let settings: PlannerSettings
    let openEventSheet: () -> Void

    private let SCALE: CGFloat = 0.65

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @EnvironmentObject private var locationService: LocationService

    private var locationLabel: String? {
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

    private var timeLabel: String? {
        let plannerTimeZoneIdentifier = planner.region(settings: settings)
            .timeZone.identifier

        let eventRegion = plannerEvent.region(
            planner: planner,
            settings: settings,
            deviceLocation: locationService.deviceLocation
        )

        let eventTimeZoneIdentifier = eventRegion.timeZone.identifier

        guard eventTimeZoneIdentifier != plannerTimeZoneIdentifier,
            let time = plannerEvent.time
        else {
            return nil
        }

        return DateInRegion(
            time,
            region: eventRegion
        ).timeWithTimezone
    }

    // MARK: - Body

    var body: some View {
        HStack {
            if let locationLabel {
                AdornedValue(
                    locationLabel,
                    iconConfig: IconConfig(
                        name: "mappin.and.ellipse",
                        primaryColor: plannerEvent.tint(
                            accentColor: accentColor
                        )
                    ),
                    color: .secondary,
                    scale: SCALE
                )
            }

            Spacer()

            if let timeLabel {
                Value(timeLabel, color: .secondary, scale: SCALE)
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: openEventSheet)
    }
}
