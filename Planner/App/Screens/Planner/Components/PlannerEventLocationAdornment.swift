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

    private let CURRENT_COORD_ID = "CURRENT"
    private let SCALE: CGFloat = 0.65

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @EnvironmentObject private var locationService: LocationService

    private var plannerTimeZoneIdentifier: String {
        planner.location(settings: settings)?.timeZoneIdentifier
            ?? TimeZone.current.identifier
    }

    private var locationContextsByTimeZoneId: [String: [LocationContext]] {
        guard plannerEvent.time != nil else { return [:] }

        let typedLocations: [TypedLocation] = [
            TypedLocation(location: plannerEvent.location, type: .event),
            TypedLocation(location: settings.homeLocation, type: .home),
            TypedLocation(location: planner.trip?.location, type: .trip),
        ]

        var contextMap: [String: [String: LocationContext]] = [:]

        let currentTimeZoneId = TimeZone.current.identifier
        let shouldDisplayCurrent =
            currentTimeZoneId != plannerTimeZoneIdentifier
        var didAddCurrent = false

        for typedLocation in typedLocations {
            guard
                let location = typedLocation.location,
                location.timeZoneIdentifier != plannerTimeZoneIdentifier
            else {
                continue
            }

            var context =
                contextMap[location.timeZoneIdentifier, default: [:]][
                    location.coordinateId
                ] ?? LocationContext(location: location)

            context.types.append(typedLocation.type)

            if shouldDisplayCurrent,
                !didAddCurrent,
                context.timeZoneId == currentTimeZoneId,
                context.location?.name == locationService.deviceLocationName
            {
                didAddCurrent = true
                context.types.append(.current)
            }

            contextMap[location.timeZoneIdentifier, default: [:]][
                location.coordinateId
            ] = context
        }

        // Add in the current location if it didn't match the other locations.
        if shouldDisplayCurrent,
            !didAddCurrent
        {
            contextMap[currentTimeZoneId, default: [:]][CURRENT_COORD_ID] =
                LocationContext(types: [.current])
        }

        return contextMap.mapValues { Array($0.values) }
    }

    private var sortedTimezones: [TimeZone] {
        locationContextsByTimeZoneId.keys
            .compactMap(TimeZone.init(identifier:))
            .sorted(by: sortTimeZones)
    }

    // MARK: - Body

    var body: some View {
        if let time = plannerEvent.time {
            Grid(horizontalSpacing: 4, verticalSpacing: 6) {
                ForEach(
                    sortedTimezones,
                    id: \.identifier
                ) { timeZone in
                    if let contexts =
                        locationContextsByTimeZoneId[timeZone.identifier]
                    {
                        let timeAndDay = DateInRegion(
                            time,
                            region: Region(
                                calendar: Calendar.current,
                                zone: timeZone,
                                locale: Locale.current
                            )
                        )

                        if let timeString = timeAndDay.timeString {
                            timeZoneRow(
                                datestamp: timeAndDay.datestamp,
                                timeString: timeString,
                                locationContexts: contexts
                            )
                        }
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
        datestamp: String,
        timeString: String,
        locationContexts: [LocationContext]
    )
        -> some View
    {
        GridRow(alignment: .top) {
            ZStack {
                if datestamp != planner.datestamp {
                    Value(
                        datestamp.weekday,
                        color: .secondary,
                        scale: SCALE
                    )
                }
            }
            .gridColumnAlignment(.trailing)

            Value(
                timeString,
                color: .secondary,
                scale: SCALE
            )
            .gridColumnAlignment(.trailing)

            VStack(alignment: .trailing, spacing: 4) {
                ForEach(
                    locationContexts.sorted(
                        by: sortLocationContexts
                    )
                ) { context in
                    AdornedValue(
                        context.locationName(
                            deviceLocationName: locationService
                                .deviceLocationName
                        ).withoutLocationContext,
                        additionalIconConfigs: context.types.map {
                            $0.iconConfig(
                                event: plannerEvent,
                                accentColor: accentColor
                            )
                        },
                        endAdorned: true,
                        color: .secondary,
                        scale: SCALE
                    )
                }
            }
            .gridColumnAlignment(.trailing)
        }
    }

    // MARK: - Functions

    private func sortTimeZones(
        lhsTimeZone: TimeZone,
        rhsTimeZone: TimeZone
    ) -> Bool {
        let now = Date()
        let lhsOffset = lhsTimeZone.secondsFromGMT(for: now)
        let rhsOffset = rhsTimeZone.secondsFromGMT(for: now)

        return lhsOffset < rhsOffset
    }

    /// Sorts alphabetically. Current location is always shifted to the bottom.
    private func sortLocationContexts(
        lhs: LocationContext,
        rhs: LocationContext
    ) -> Bool {
        guard let lhsLocation = lhs.location else {
            return false
        }

        guard let rhsLocation = rhs.location else {
            return true
        }

        return lhsLocation.name < rhsLocation.name
    }

}
