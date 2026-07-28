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

    private var plannerTimeZoneIdentifier: String {
        planner.location(settings: settings)?.timeZoneIdentifier
            ?? TimeZone.current.identifier
    }

    private var homeLocation: Location? {
        settings.homeLocation
    }

    private var tripLocation: Location? {
        planner.trip?.location
    }

    private var eventLocation: Location? {
        plannerEvent.location
    }

    private var locationContextsByTimezoneId: [String: [LocationContext]] {
        guard plannerEvent.time != nil else { return [:] }

        let locations: [LocationContext?] = [
            eventLocation.map(LocationContext.event),
            homeLocation.map(LocationContext.home),
            tripLocation.map(LocationContext.trip),
        ]

        var contextMap: [String: [LocationContext]] = [:]
        var coordinateIds: Set<String> = []
        let currentTimeZoneId = TimeZone.current.identifier

        // Filter out duplicate locations.
        for context in locations {
            guard
                let context,
                let location = context.location,
                location.timeZoneIdentifier != plannerTimeZoneIdentifier,
                !coordinateIds.contains(location.coordinateId)
            else {
                continue
            }

            coordinateIds.insert(location.coordinateId)

            contextMap[location.timeZoneIdentifier, default: []].append(
                context
            )
        }

        // Only display local time when it doesn't match any of the other timezones.
        if currentTimeZoneId != plannerTimeZoneIdentifier,
            contextMap[currentTimeZoneId] == nil
        {
            contextMap[currentTimeZoneId] = [
                LocationContext.current
            ]
        }

        return contextMap
    }

    // MARK: - Body

    var body: some View {
        if let time = plannerEvent.time {
            Grid(horizontalSpacing: 6, verticalSpacing: 4) {
                ForEach(
                    locationContextsByTimezoneId.keys.sorted(),
                    id: \.self
                ) { timeZoneId in
                    if let contexts = locationContextsByTimezoneId[timeZoneId],
                        let timeZone = TimeZone(identifier: timeZoneId),
                        let timeString = DateInRegion(
                            time,
                            region: Region(
                                calendar: Calendar.current,
                                zone: timeZone,
                                locale: Locale.current
                            )
                        ).timeString
                    {
                        timeZoneRow(
                            timeString: timeString,
                            locations: contexts
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .contentShape(Rectangle())
            .onTapGesture(perform: openEventSheet)
        }
    }

    // MARK: - View Builders

    private func timeZoneRow(
        timeString: String,
        locations: [LocationContext]
    )
        -> some View
    {
        let split = splitLocations(locations)

        return GridRow {
            HStack(spacing: 4) {
                ForEach(Array(split.unlabeled.enumerated()), id: \.element.id) {
                    index,
                    location in
                    AdornedValue(
                        iconConfig: location.iconConfig(
                            event: plannerEvent,
                            accentColor: accentColor
                        ),
                        color: .secondary,
                        scale: SCALE
                    )

                    if index < split.unlabeled.count - 1
                        || !split.labeled.isEmpty
                    {
                        Value(
                            "+",
                            color: .tertiary,
                            scale: SCALE
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(split.labeled) { location in
                        AdornedValue(
                            location.location?.name,
                            iconConfig: location.iconConfig(
                                event: plannerEvent,
                                accentColor: accentColor
                            ),
                            color: .secondary,
                            scale: SCALE
                        )
                    }
                }
            }
            .gridColumnAlignment(.trailing)

            Value(
                timeString,
                color: .secondary,
                scale: SCALE
            )
            .gridColumnAlignment(.trailing)
        }
    }

    // MARK: - Functions

    /// Organizes locations into labeled (with text) and unlabeled (icon only).
    private func splitLocations(_ locations: [LocationContext]) -> (
        unlabeled: [LocationContext],
        labeled: [LocationContext]
    ) {
        locations.reduce(into: (unlabeled: [], labeled: [])) {
            result,
            location in
            if location.displayLocationName {
                result.labeled.append(location)
            } else {
                result.unlabeled.append(location)
            }
        }
    }
}
